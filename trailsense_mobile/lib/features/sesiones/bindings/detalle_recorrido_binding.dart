import 'package:get/get.dart';
import '../presentation/controllers/detalle_recorrido_controller.dart';

class DetalleRecorridoBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DetalleRecorridoController(), permanent: false);
  }
}