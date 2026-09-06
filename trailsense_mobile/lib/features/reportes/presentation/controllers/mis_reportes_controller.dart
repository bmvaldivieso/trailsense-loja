import 'package:get/get.dart';
import '../../data/models/reporte_model.dart';
import '../../data/repositories/reportes_repository.dart';

class MisReportesController extends GetxController {
  final ReportesRepository _repository = ReportesRepository();

  final RxList<ReporteModel> reportes = <ReporteModel>[].obs;
  final RxBool isLoading = false.obs;

  final RxBool mostrarBusqueda = false.obs;
  final RxString busqueda = ''.obs;

  @override
  void onInit() {
    super.onInit();
    cargarMisReportes();
  }

  Future<void> cargarMisReportes() async {
    try {
      isLoading.value = true;
      reportes.value = await _repository.listarReportes(soloMios: true);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar tus reportes');
    } finally {
      isLoading.value = false;
    }
  }


  List<ReporteModel> get reportesFiltrados {
    if (busqueda.value.trim().isEmpty) return reportes;
    final texto = busqueda.value.trim().toLowerCase();
    return reportes.where((r) =>
        r.senderoNombre.toLowerCase().contains(texto) ||
        r.descripcion.toLowerCase().contains(texto)
    ).toList();
  }

  void toggleBusqueda() {
    mostrarBusqueda.value = !mostrarBusqueda.value;
    if (!mostrarBusqueda.value) busqueda.value = '';
  }

  void actualizarBusqueda(String texto) => busqueda.value = texto;
}