import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 28.w,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 1. Logo
              Image.asset(
                'assets/images/logo_trailsense.png',
                height: 140.h,
                width: 140.w,
              ),

              SizedBox(height: 32.h),

              // 2. Nombre de la App
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: 'TrailSense ',
                      style: TextStyle(
                        color: const Color(0xFF60A5FA),
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'Loja',
                      style: TextStyle(
                        color: const Color(0xFF1E40AF),
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // 3. Botón Iniciar
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C8DFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Iniciar',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}