import 'package:get/get.dart';
import '../presentation/controllers/perfil_controller.dart';

class PerfilBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PerfilController>(() => PerfilController());
  }
}