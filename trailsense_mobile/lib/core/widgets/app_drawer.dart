import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../storage/token_storage.dart';
import '../../features/auth/presentation/controllers/login_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _cerrarSesion() async {
    final confirmado = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF3B82F6)),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      TokenStorage().clear();

      if (Get.isRegistered<LoginController>()) {
        Get.find<LoginController>().limpiarCampos();
      }

      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3B82F6)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trail Sense Loja',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, size: 24.r),
              title: Text('Perfil', style: TextStyle(fontSize: 16.sp)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, size: 24.r),
              title: Text('Configuración', style: TextStyle(fontSize: 16.sp)),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent, size: 24.r),
              title: Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.redAccent, fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _cerrarSesion();
              },
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
