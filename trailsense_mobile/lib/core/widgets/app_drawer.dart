import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
              title: Text(
                'Perfil',
                style: TextStyle(fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                // Get.toNamed(AppRoutes.perfil);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, size: 24.r),
              title: Text(
                'Configuración',
                style: TextStyle(fontSize: 16.sp),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent, size: 24.r),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.redAccent, fontSize: 16.sp),
              ),
              onTap: () {
                // Controller de auth: cerrar sesión
              },
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}