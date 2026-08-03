import 'package:get/get.dart';

class HomeController extends GetxController {
  // Manejo de pestaña activa del BottomNavigationBar
  final RxInt currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}