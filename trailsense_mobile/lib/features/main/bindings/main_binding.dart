import 'package:get/get.dart';
import '../presentation/controllers/main_controller.dart';
import '../../home/presentation/controllers/home_controller.dart';
import '../../senderos/presentation/controllers/senderos_controller.dart';
import '../../sesiones/presentation/controllers/sesiones_controller.dart';
import '../../reportes/presentation/controllers/reportes_controller.dart';

import '../../perfil/presentation/controllers/perfil_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<SenderosController>(() => SenderosController());
    Get.lazyPut<SesionesController>(() => SesionesController());
    Get.lazyPut<ReportesController>(() => ReportesController());

    Get.lazyPut<PerfilController>(() => PerfilController(), fenix: true); 
  }
}