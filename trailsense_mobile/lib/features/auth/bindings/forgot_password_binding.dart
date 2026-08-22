import 'package:get/get.dart';
import '../presentation/controllers/forgot_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ForgotPasswordController>()) {
      Get.put(ForgotPasswordController(), permanent: false);
    }
  }
}