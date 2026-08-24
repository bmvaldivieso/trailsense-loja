import 'package:get/get.dart';
import '../presentation/controllers/detalle_sendero_controller.dart';

class DetalleSenderoBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DetalleSenderoController(), permanent: false);
  }
}