import 'package:get/get.dart';

import '../presentation/controllers/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RegisterController>()) {
      Get.put(
        RegisterController(),
        permanent: false,
      );
    }
  }
}