import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // 1. Espera 1 segundo en pantalla azul estática
    await Future.delayed(const Duration(seconds: 1));

    // 2. Duración del GIF (ajustar según tu archivo)
    await Future.delayed(const Duration(seconds: 2));

    // 3. Navegación a la pantalla de bienvenida mediante GetX
    Get.offNamed('/welcome');
  }
}