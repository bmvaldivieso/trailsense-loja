import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/reportes_repository.dart';
import '../../../senderos/data/models/sendero_model.dart';
import '../../../senderos/data/repositories/senderos_repository.dart';

import 'package:dio/dio.dart';


class CrearReporteController extends GetxController {
  final ReportesRepository _repository = ReportesRepository();
  final SenderosRepository _senderosRepository = SenderosRepository();

  // Si viene de "Crear Incidencia" en detalle de sendero, ya está fijo.
  final Rx<int?> senderoIdFijo = Rx<int?>(null);
  final RxString senderoNombreFijo = ''.obs;

  // Si NO viene fijo, se muestra un selector con esta lista.
  final RxList<SenderoModel> senderosDisponibles = <SenderoModel>[].obs;
  final Rx<int?> senderoSeleccionado = Rx<int?>(null);

  final RxString categoriaSeleccionada = 'deterioro'.obs;
  final descripcionCtrl = TextEditingController();
  final RxInt caracteresRestantes = 500.obs;

  final RxList<File> fotos = <File>[].obs;
  final RxBool isLoading = false.obs;

  static const int maxCaracteres = 500;
  static const int maxFotos = 5;

  // Configuración de precisión
  static const double _precisionDeseadaM = 9;          // Umbral aceptable en metros
  static const Duration _tiempoMaximoGps = Duration(seconds: 15); // Tope de espera

  final RxString estadoUbicacion = ''.obs; // Para mostrar feedback en la UI

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map && args['senderoId'] != null) {
      senderoIdFijo.value = args['senderoId'] as int;
      senderoNombreFijo.value = args['senderoNombre'] as String? ?? '';
    } else {
      _cargarSenderosDisponibles();
    }

    descripcionCtrl.addListener(() {
      caracteresRestantes.value = maxCaracteres - descripcionCtrl.text.length;
    });
  }

  // Obtiene la mejor ubicación posible dentro de un tiempo límite
  Future<Position> _obtenerUbicacionPrecisa() async {
    final permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      final solicitado = await Geolocator.requestPermission();
      if (solicitado == LocationPermission.denied || solicitado == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado');
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      throw Exception('El GPS del dispositivo está desactivado');
    }

    Position? mejorLectura;
    final completer = Completer<Position>();
    late StreamSubscription<Position> subscripcion;

    final timer = Timer(_tiempoMaximoGps, () {
      subscripcion.cancel();
      if (!completer.isCompleted) {
        if (mejorLectura != null) {
          completer.complete(mejorLectura);
        } else {
          completer.completeError(Exception('No se pudo obtener la ubicación'));
        }
      }
    });

    subscripcion = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0),
    ).listen((posicion) {
      if (mejorLectura == null || posicion.accuracy < mejorLectura!.accuracy) {
        mejorLectura = posicion;
        estadoUbicacion.value = 'Precisión actual: ${posicion.accuracy.toStringAsFixed(0)} m';
      }

      if (posicion.accuracy <= _precisionDeseadaM) {
        timer.cancel();
        subscripcion.cancel();
        if (!completer.isCompleted) completer.complete(posicion);
      }
    }, onError: (e) {
      timer.cancel();
      if (!completer.isCompleted) completer.completeError(e);
    });

    return completer.future;
  }

  Future<void> _cargarSenderosDisponibles() async {
    try {
      senderosDisponibles.value = await _senderosRepository.listarSenderos();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los senderos');
    }
  }

  void seleccionarCategoria(String valor) => categoriaSeleccionada.value = valor;

  Future<void> agregarFotoDesdeCamara() async {
    if (fotos.length >= maxFotos) {
      Get.snackbar('Límite alcanzado', 'Puedes adjuntar máximo $maxFotos fotos.');
      return;
    }
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (foto != null) fotos.add(File(foto.path));
  }

  Future<void> agregarFotoDesdeGaleria() async {
    if (fotos.length >= maxFotos) {
      Get.snackbar('Límite alcanzado', 'Puedes adjuntar máximo $maxFotos fotos.');
      return;
    }
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (foto != null) fotos.add(File(foto.path));
  }

  void quitarFoto(int index) => fotos.removeAt(index);

  Future<void> enviarReporte() async {
    final senderoId = senderoIdFijo.value ?? senderoSeleccionado.value;

    if (senderoId == null) {
      Get.snackbar('Falta información', 'Selecciona el sendero relacionado.');
      return;
    }
    if (fotos.isEmpty) {
      Get.snackbar('Falta información', 'Debes adjuntar al menos una foto.');
      return;
    }
    if (descripcionCtrl.text.trim().isEmpty) {
      Get.snackbar('Falta información', 'Describe el incidente.');
      return;
    }

    try {
      isLoading.value = true;
      estadoUbicacion.value = 'Obteniendo ubicación precisa...';

      final posicion = await _obtenerUbicacionPrecisa();

      await _repository.crearReporte(
        senderoId: senderoId,
        lat: posicion.latitude,
        lon: posicion.longitude,
        altitud: posicion.altitude,
        categoria: categoriaSeleccionada.value,
        descripcion: descripcionCtrl.text.trim(),
        fotos: fotos,
      );

      Get.offNamed('/reporte-enviado');
      } catch (e) {
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map<String, dynamic> && data['message'] != null) {
            Get.snackbar('No se pudo enviar el reporte', data['message']);
            return;
          }
        }
        Get.snackbar('Error', 'No se pudo enviar el reporte. Intenta nuevamente.');
      } finally {
        isLoading.value = false;
        estadoUbicacion.value = '';
      }
  }

  @override
  void onClose() {
    descripcionCtrl.dispose();
    super.onClose();
  }
}