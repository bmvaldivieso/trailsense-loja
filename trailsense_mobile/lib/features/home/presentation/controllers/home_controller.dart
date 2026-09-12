import 'package:get/get.dart';
import '../../../senderos/presentation/controllers/senderos_controller.dart';
import '../../../reportes/presentation/controllers/reportes_controller.dart';

class HomeController extends GetxController {
  // Reutiliza los controllers ya existentes — Home no vuelve a pedir
  // datos ni duplica lógica de filtros/búsqueda.
  SenderosController get senderosController => Get.find<SenderosController>();
  ReportesController get reportesController => Get.find<ReportesController>();

  final RxBool mostrarBusqueda = false.obs;

  void alternarBusqueda() {
    mostrarBusqueda.value = !mostrarBusqueda.value;
    if (!mostrarBusqueda.value) {
      senderosController.actualizarBusqueda('');
    }
  }
}