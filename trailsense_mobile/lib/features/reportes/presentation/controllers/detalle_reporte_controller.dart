import 'package:get/get.dart';
import '../../data/models/reporte_model.dart';
import '../../data/repositories/reportes_repository.dart';

class DetalleReporteController extends GetxController {
  final ReportesRepository _repository = ReportesRepository();

  final Rx<ReporteModel?> reporte = Rx<ReporteModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments as int?;
    if (id != null) cargarReporte(id);
  }

  Future<void> cargarReporte(int id) async {
    try {
      isLoading.value = true;
      reporte.value = await _repository.obtenerReporte(id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el reporte');
    } finally {
      isLoading.value = false;
    }
  }
}