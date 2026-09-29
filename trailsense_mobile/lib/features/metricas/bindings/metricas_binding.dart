import 'package:get/get.dart';
import '../presentation/controllers/metricas_controller.dart';

class MetricasBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MetricasController(), permanent: false);
  }
}