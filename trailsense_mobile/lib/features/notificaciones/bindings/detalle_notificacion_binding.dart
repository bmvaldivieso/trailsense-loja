import 'package:get/get.dart';
import '../presentation/controllers/detalle_notificacion_controller.dart';

class DetalleNotificacionBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DetalleNotificacionController(), permanent: false);
  }
}