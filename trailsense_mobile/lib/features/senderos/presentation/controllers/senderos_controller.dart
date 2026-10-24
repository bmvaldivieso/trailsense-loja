import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/sendero_model.dart';
import '../../data/repositories/senderos_repository.dart';

import '../../../main/presentation/controllers/main_controller.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/location/ajustes_gps.dart';

class SenderosController extends GetxController {

  static const LatLng _centroLoja = LatLng(-3.9973, -79.2005);

  final SenderosRepository _repository = SenderosRepository();
  final MapController mapController = MapController();

  final RxList<SenderoModel> senderos = <SenderoModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<SenderoModel?> senderoSeleccionado = Rx<SenderoModel?>(null);

  final RxString filtroDificultad = ''.obs;
  final RxString filtroEstado = ''.obs;
  final RxString busqueda = ''.obs;
  final Rx<LatLng?> ubicacionActual = Rx<LatLng?>(null);
  final RxBool buscandoUbicacion = false.obs;

  final RxDouble precisionM = 0.0.obs; // precisión (radio de error) de la última lectura, en metros

  static const double _precisionObjetivoM = 5;                     // se detiene al alcanzar esta precisión
  static const Duration _tiempoMaxLectura = Duration(seconds: 20); // tope de espera

  LatLng get centroInicial => _centroLoja;

  @override
  void onInit() {
    super.onInit();
    cargarSenderos();
    _inicializarUbicacion();

    // Recarga cada vez que el usuario entra al tab de Senderos
    if (Get.isRegistered<MainController>()) {
      ever<int>(Get.find<MainController>().currentIndex, (index) {
        if (index == 1) { // índice del tab "Senderos" en el bottom nav
          cargarSenderos();
        }
      });
    }
  }

  List<SenderoModel> get senderosFiltrados {
    if (busqueda.value.trim().isEmpty) return senderos;
    final texto = busqueda.value.trim().toLowerCase();
    return senderos.where((s) => s.nombre.toLowerCase().contains(texto)).toList();
  }

  void actualizarBusqueda(String texto) {
    busqueda.value = texto;
  }

  Future<void> _inicializarUbicacion() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) return;

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final punto = LatLng(posicion.latitude, posicion.longitude);
      ubicacionActual.value = punto;
      mapController.move(punto, 15);
    } catch (e) {
      // Fallback a Loja si ocurre un error
    }
  }

  /// Escucha el GPS hasta alcanzar la precisión objetivo o agotar el tiempo,
  /// y devuelve la MEJOR lectura. Mueve el punto del mapa mientras mejora.
  Future<Position> _lecturaPrecisa() async {
    
    final LocationSettings ajustes = ajustesGpsAltaPrecision();

    final inicio = DateTime.now();
    Position? mejor;
    final completer = Completer<Position>();
    late StreamSubscription<Position> suscripcion;

    final temporizador = Timer(_tiempoMaxLectura, () {
      suscripcion.cancel();
      if (completer.isCompleted) return;
      if (mejor != null) {
        completer.complete(mejor);
      } else {
        completer.completeError(TimeoutException('Sin lectura de GPS'));
      }
    });

    suscripcion = Geolocator.getPositionStream(locationSettings: ajustes).listen(
      (p) {
        // Descarta lecturas en caché anteriores a esta solicitud
        final DateTime? ts = p.timestamp;
        if (ts != null && ts.isBefore(inicio.subtract(const Duration(seconds: 2)))) return;

        if (mejor == null || p.accuracy < mejor!.accuracy) {
          mejor = p;
          // El punto rojo se va corrigiendo mientras la lectura mejora
          ubicacionActual.value = LatLng(p.latitude, p.longitude);
          precisionM.value = p.accuracy;
        }

        if (p.accuracy <= _precisionObjetivoM) {
          temporizador.cancel();
          suscripcion.cancel();
          if (!completer.isCompleted) completer.complete(p);
        }
      },
      onError: (e) {
        temporizador.cancel();
        suscripcion.cancel();
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    return completer.future;
  }

  Future<void> centrarEnMiUbicacion() async {
    if (buscandoUbicacion.value) return; // evita lecturas simultáneas por toques repetidos

    // Respuesta inmediata: centra en la última ubicación conocida mientras se recalcula
    if (ubicacionActual.value != null) {
      mapController.move(ubicacionActual.value!, 15);
    }

    buscandoUbicacion.value = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        Get.snackbar('GPS desactivado', 'Activa la ubicación del dispositivo para centrarte en el mapa.');
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        Get.snackbar('Permiso denegado', 'Permite el acceso a la ubicación para usar esta función.');
        return;
      }

      // Lectura de alta precisión
      final posicion = await _lecturaPrecisa();

      final punto = LatLng(posicion.latitude, posicion.longitude);
      ubicacionActual.value = punto;
      precisionM.value = posicion.accuracy;
      mapController.move(punto, 17); // más zoom para apreciar la posición exacta
    } on TimeoutException {
      Get.snackbar('Ubicación', 'No se pudo obtener una ubicación precisa. Intenta nuevamente al aire libre.');
    } catch (e) {
      Get.snackbar('Ubicación', 'No se pudo actualizar tu ubicación.');
    } finally {
      buscandoUbicacion.value = false;
    }
  }

  Future<void> cargarSenderos() async {
    try {
      isLoading.value = true;
      final resultado = await _repository.listarSenderos(
        dificultad: filtroDificultad.value.isEmpty ? null : filtroDificultad.value,
        estado: filtroEstado.value.isEmpty ? null : filtroEstado.value,
      );
      senderos.value = resultado;
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los senderos');
    } finally {
      isLoading.value = false;
    }
  }

  void aplicarFiltro({String? dificultad, String? estado}) {
    if (dificultad != null) filtroDificultad.value = dificultad;
    if (estado != null) filtroEstado.value = estado;
    cargarSenderos();
  }

  void limpiarFiltros() {
    filtroDificultad.value = '';
    filtroEstado.value = '';
    cargarSenderos();
  }

  void seleccionarSendero(SenderoModel sendero) {
    senderoSeleccionado.value = sendero;
    if (sendero.puntos.length > 1) {
      final bounds = LatLngBounds.fromPoints(sendero.puntos);
      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    } else {
      mapController.move(sendero.puntoInicio, 15);
    }
  }
}