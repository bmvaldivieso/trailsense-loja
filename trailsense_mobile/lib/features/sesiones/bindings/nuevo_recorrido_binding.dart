import 'package:get/get.dart';
import '../presentation/controllers/nuevo_recorrido_controller.dart';

class NuevoRecorridoBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NuevoRecorridoController(), permanent: false);
  }
}