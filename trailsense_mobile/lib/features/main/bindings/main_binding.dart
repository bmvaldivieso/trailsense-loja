import 'package:get/get.dart';
import '../presentation/controllers/main_controller.dart';
import '../../home/presentation/controllers/home_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}