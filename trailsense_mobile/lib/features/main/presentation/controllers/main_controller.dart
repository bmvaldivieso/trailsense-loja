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

  void changePage(int index) {
    currentIndex.value = index;
  }
}