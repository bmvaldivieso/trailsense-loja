import 'package:get/get.dart';
import '../../data/models/reporte_model.dart';
import '../../data/repositories/reportes_repository.dart';

import '../../../senderos/data/models/sendero_model.dart';
import '../../../senderos/data/repositories/senderos_repository.dart';

class DetalleReporteController extends GetxController {
  final ReportesRepository _repository = ReportesRepository();
  final SenderosRepository _senderosRepository = SenderosRepository();

  final Rx<ReporteModel?> reporte = Rx<ReporteModel?>(null);
  final Rx<SenderoModel?> senderoAsociado = Rx<SenderoModel?>(null);
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
      if (reporte.value != null) {
        _cargarSenderoAsociado(reporte.value!.senderoId);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el reporte');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cargarSenderoAsociado(int senderoId) async {
    try {
      senderoAsociado.value = await _senderosRepository.obtenerSendero(senderoId);
    } catch (e) {
      // Silencioso: si falla, el detalle del reporte igual se muestra sin el trazado
    }
  }
}