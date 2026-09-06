import 'package:get/get.dart';
import '../presentation/controllers/crear_reporte_controller.dart';

class CrearReporteBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CrearReporteController(), permanent: false);
  }
}