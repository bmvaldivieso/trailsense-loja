import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/reportes_repository.dart';
import '../../../senderos/data/models/sendero_model.dart';
import '../../../senderos/data/repositories/senderos_repository.dart';

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

      final posicion = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

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
      Get.snackbar('Error', 'No se pudo enviar el reporte. Intenta nuevamente.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    descripcionCtrl.dispose();
    super.onClose();
  }
}