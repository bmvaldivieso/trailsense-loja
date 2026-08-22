import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: Container(
                  width: 260.r,
                  height: 260.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: Center(
                    child: Container(
                      width: 200.r,
                      height: 200.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                      child: Center(
                        child: Container(
                          width: 140.r,
                          height: 140.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            size: 80.sp,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'Contraseña\nrestablecida',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Ya puedes iniciar sesión con tu nueva contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const Spacer(flex: 5),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAllNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7FA),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Ir a iniciar sesión',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 64.h),
            ],
          ),
        ),
      ),
    );
  }
}