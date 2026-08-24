import 'package:get/get.dart';
import '../presentation/controllers/senderos_controller.dart';

class SenderosBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SenderosController>()) {
      Get.put(SenderosController(), permanent: false);
    }
  }
}