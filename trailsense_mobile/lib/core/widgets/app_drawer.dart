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
    const iconColor = Color(0xFF3B82F6);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Mi perfil con Avatar de usuario
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: CircleAvatar(
                  radius: 18.r,
                  // Imagen de placeholder online
                  backgroundImage: const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                  backgroundColor: Colors.grey.shade300,
                ),
                title: Text(
                  'Mi perfil',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed('/perfil');
                },
              ),

              // 2. Historial Recorridos
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: Icon(Icons.sync_rounded, color: iconColor, size: 26.r),
                title: Text(
                  'Historial Recorridos',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),

              // 3. Métricas Personales
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: Icon(Icons.insert_chart_outlined_rounded, color: iconColor, size: 26.r),
                title: Text(
                  'Métricas Personales',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),

              // 4. Notificaciones
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: Icon(Icons.notifications_none_rounded, color: iconColor, size: 26.r),
                title: Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),

              // 5. Ayuda y soporte
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: Icon(Icons.help_outline_rounded, color: iconColor, size: 26.r),
                title: Text(
                  'Ayuda y soporte',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),

              // 6. Cerrar Sesión
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: Icon(Icons.logout_rounded, color: iconColor, size: 26.r),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cerrarSesion();
                },
              ),

              const Spacer(),

              // 7. Ajustes / Configuración
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: Icon(Icons.settings_outlined, color: iconColor, size: 26.r),
                title: Text(
                  'Ajustes',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}