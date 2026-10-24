import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/reporte_model.dart';
import '../../data/repositories/reportes_repository.dart';
import '../../../../core/constants/categorias_reporte.dart';
import '../../../../core/utils/texto.dart';

import '../../../senderos/presentation/controllers/senderos_controller.dart';
import '../../../senderos/data/models/sendero_model.dart';

class ReportesController extends GetxController {
  final ReportesRepository _repository = ReportesRepository();

  final MapController mapController = MapController();
  final TextEditingController busquedaCtrl = TextEditingController();

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

  @override
  void onClose() {
    busquedaCtrl.dispose();
    super.onClose();
  }

  /// Busca por tipo, descripción, fecha, autor y sendero.
  /// Con varias palabras, todas deben coincidir (ej.: "obstaculo 24/10").
  List<ReporteModel> get reportesFiltrados {
    final List<String> terminos = normalizarTexto(busqueda.value)
        .split(RegExp(r'\s+'))
        .where((String t) => t.isNotEmpty)
        .toList();
    if (terminos.isEmpty) return reportes;

    return reportes.where((ReporteModel r) {
      final String indice = _indiceBusqueda(r);
      return terminos.every(indice.contains);
    }).toList();
  }

  String _indiceBusqueda(ReporteModel r) {
    final DateTime f = r.fechaCreacion.toLocal();
    String dos(int v) => v.toString().padLeft(2, '0');
    final CategoriaReporte cat = categoriaPorValor(r.categoria);

    return normalizarTexto(<String>[
      cat.etiqueta,                               // tipo (ej.: "Riesgo de seguridad")
      r.categoria,                                // tipo (valor interno: "seguridad")
      r.descripcion,
      r.usuarioNombre,                            // autor
      r.senderoNombre,                            // se mantiene la búsqueda anterior
      r.fechaTexto,                               // 24/10/2026
      '${f.day}/${f.month}/${f.year}',            // 4/9/2026
      '${dos(f.day)}-${dos(f.month)}-${f.year}',  // 24-10-2026
      '${f.year}-${dos(f.month)}-${dos(f.day)}',  // 2026-10-24
    ].join(' '));
  }

  void actualizarBusqueda(String texto) => busqueda.value = texto;

  void limpiarBusqueda() {
    busquedaCtrl.clear();
    busqueda.value = '';
  }

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

  List<SenderoModel> get senderosParaDibujar {
    if (Get.isRegistered<SenderosController>()) {
      return Get.find<SenderosController>().senderos;
    }
    return [];
  }
}