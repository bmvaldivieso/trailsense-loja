import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/models/sesion_model.dart';
import '../../data/repositories/sesiones_repository.dart';

class SesionesController extends GetxController {
  final SesionesRepository _repository = SesionesRepository();

  final MapController mapController = MapController();

  final RxList<SesionModel> sesiones = <SesionModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<SesionModel?> sesionSeleccionada = Rx<SesionModel?>(null);

  static const LatLng _centroLoja = LatLng(-3.9973, -79.2005);
  LatLng get centroInicial => _centroLoja;

  @override
  void onInit() {
    super.onInit();
    cargarSesiones();
  }

  Future<void> cargarSesiones() async {
    try {
      isLoading.value = true;
      sesiones.value = await _repository.listarSesiones();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar tus recorridos');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> seleccionarSesion(SesionModel sesionResumen) async {
    try {
      // Trae el detalle completo, que incluye la traza
      final sesionCompleta = await _repository.obtenerSesion(sesionResumen.id);
      sesionSeleccionada.value = sesionCompleta;

      final destino = sesionCompleta.puntoInicio ??
          (sesionCompleta.traza.isNotEmpty ? sesionCompleta.traza.first : null);

      if (destino == null) {
        Get.snackbar('Aviso', 'Este recorrido no tiene ubicación registrada.');
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          mapController.move(destino, 15);
        } catch (e) {
          debugPrint('Error moviendo el mapa: $e');
        }
      });
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el recorrido seleccionado.');
    }
  }
}