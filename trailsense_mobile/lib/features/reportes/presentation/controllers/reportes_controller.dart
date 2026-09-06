import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/models/reporte_model.dart';
import '../../data/repositories/reportes_repository.dart';

class ReportesController extends GetxController {
  final ReportesRepository _repository = ReportesRepository();

  final MapController mapController = MapController();

  final RxList<ReporteModel> reportes = <ReporteModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filtroCategoria = ''.obs;
  final RxString busqueda = ''.obs;

  static const LatLng _centroLoja = LatLng(-3.9973, -79.2005);
  LatLng get centroInicial => _centroLoja;

  @override
  void onInit() {
    super.onInit();
    cargarReportes();
  }

  List<ReporteModel> get reportesFiltrados {
    if (busqueda.value.trim().isEmpty) return reportes;
    final texto = busqueda.value.trim().toLowerCase();
    return reportes.where((r) => r.descripcion.toLowerCase().contains(texto) || r.senderoNombre.toLowerCase().contains(texto)).toList();
  }

  void actualizarBusqueda(String texto) => busqueda.value = texto;

  Future<void> cargarReportes() async {
    try {
      isLoading.value = true;
      reportes.value = await _repository.listarReportes(
        categoria: filtroCategoria.value.isEmpty ? null : filtroCategoria.value,
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los reportes');
    } finally {
      isLoading.value = false;
    }
  }

  void aplicarFiltro(String categoria) {
    filtroCategoria.value = categoria;
    cargarReportes();
  }

  void limpiarFiltros() {
    filtroCategoria.value = '';
    cargarReportes();
  }

  void seleccionarReporte(ReporteModel reporte) {
    mapController.move(LatLng(reporte.lat, reporte.lon), 16);
  }
}