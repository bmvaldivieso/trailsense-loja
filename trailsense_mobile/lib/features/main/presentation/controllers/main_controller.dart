import 'package:get/get.dart';

class MainController extends GetxController {
  final RxInt currentIndex = 0.obs;

  // Títulos del AppBar por pestaña
  final List<String> titles = const [
    'Trail Sense Loja',
    'Senderos',
    'Iniciar Recorrido',
    'Reportes',
    'Notificaciones',
  ];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int && args >= 0 && args < titles.length) {
      currentIndex.value = args;
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
  }
}