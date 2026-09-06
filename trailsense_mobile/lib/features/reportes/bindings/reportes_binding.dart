import 'package:get/get.dart';
import '../presentation/controllers/reportes_controller.dart';

class ReportesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ReportesController>()) {
      Get.put(ReportesController(), permanent: false);
    }
  }
}