import 'package:get/get.dart';
import '../presentation/controllers/mis_reportes_controller.dart';

class MisReportesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MisReportesController(), permanent: false);
  }
}