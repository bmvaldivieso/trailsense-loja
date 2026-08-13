import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../senderos/presentation/screens/senderos_screen.dart';
import '../../../sesiones/presentation/screens/sesiones_screen.dart';
import '../../../reportes/presentation/screens/reportes_screen.dart';
import '../../../notificaciones/presentation/screens/notificaciones_screen.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  static const List<Widget> _pages = [
    HomeScreen(),
    SenderosScreen(),
    SesionesScreen(),
    ReportesScreen(),
    NotificacionesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: controller.titles[controller.currentIndex.value],
        ),
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: _pages,
        ),
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changePage,
        ),
      ),
    );
  }
}