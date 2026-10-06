import 'package:get/get.dart';

import '../../data/models/notificacion_model.dart';
import '../../data/repositories/notificaciones_repository.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class DetalleNotificacionController extends GetxController {
  final NotificacionesRepository _repository = NotificacionesRepository();

  final Rx<NotificacionModel?> notificacion = Rx<NotificacionModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments as int?;
    if (id != null) cargar(id);
  }

  Future<void> cargar(int id) async {
    try {
      isLoading.value = true;
      notificacion.value = await _repository.obtener(id);   // el servidor la marca como leída
    } catch (_) {
      Get.snackbar('Error', 'No se pudo cargar la notificación.');
    } finally {
      isLoading.value = false;
    }
  }

  bool get tieneRelacionado => notificacion.value?.reporteId != null || notificacion.value?.senderoId != null;

  Future<void> abrirRelacionado() async {
    final n = notificacion.value;
    if (n == null) return;

    if (n.reporteId != null) {
      await Get.toNamed('/detalle-reporte', arguments: n.reporteId);
    } else if (n.senderoId != null) {
      await Get.toNamed('/detalle-sendero', arguments: n.senderoId);
    }
    // Esas pantallas cambian la pestaña al volver; se restaura la de notificaciones
    if (Get.isRegistered<MainController>()) Get.find<MainController>().changePage(4);
  }
}