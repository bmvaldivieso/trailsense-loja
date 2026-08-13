import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 72.h),

              // Logo
              Center(
                child: Container(
                  width: 180.w,
                  height: 180.h,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00C6FF),
                        Color(0xFF7000FF),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/logo_trailsense.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comience con:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Redes sociales todavía fuera del alcance
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      backgroundColor: const Color(0xFF3B5998),
                      child: Text(
                        'f',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _SocialButton(
                      backgroundColor: Colors.white,
                      hasBorder: true,
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _SocialButton(
                      backgroundColor: Colors.white,
                      hasBorder: true,
                      child: Icon(
                        Icons.phone,
                        color: const Color(0xFF52B788),
                        size: 26.sp,
                      ),
                      onTap: null,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'O regístrese con:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Registro mediante correo
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/register-form');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C8DFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Correo',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Ya tienes cuenta? ',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.offAllNamed('/login');
                    },
                    child: Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFCC0000),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final bool hasBorder;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.child,
    required this.backgroundColor,
    this.hasBorder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: hasBorder
              ? Border.all(
                  color: Colors.grey.shade300,
                  width: 1.w,
                )
              : null,
          boxShadow: hasBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}