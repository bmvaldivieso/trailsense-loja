import 'package:get/get.dart';
import '../presentation/controllers/detalle_reporte_controller.dart';

class DetalleReporteBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DetalleReporteController(), permanent: false);
  }
}