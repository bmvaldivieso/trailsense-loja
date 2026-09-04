import 'package:get/get.dart';
import '../presentation/controllers/sesiones_controller.dart';

class SesionesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SesionesController>()) {
      Get.put(SesionesController(), permanent: false);
    }
  }
}