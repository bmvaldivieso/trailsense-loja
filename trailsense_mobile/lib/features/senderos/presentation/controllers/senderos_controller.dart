import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/sendero_model.dart';
import '../../data/repositories/senderos_repository.dart';

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

  LatLng get centroInicial => _centroLoja;

  @override
  void onInit() {
    super.onInit();
    cargarSenderos();
    _inicializarUbicacion();
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

  Future<void> centrarEnMiUbicacion() async {
    if (ubicacionActual.value != null) {
      mapController.move(ubicacionActual.value!, 15);
    } else {
      await _inicializarUbicacion();
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
    filtroDificultad.value = dificultad ?? '';
    filtroEstado.value = estado ?? '';
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