import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class VerifyCodeScreen extends StatelessWidget {
  const VerifyCodeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24.sp,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // Título "Introduce el código de activación"
              Text(
                'Introduce el código de\nactivación',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2B2B2B),
                  height: 1.2,
                ),
              ),

              SizedBox(height: 40.h),

              // Contenedores de las casillas OTP / Código
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCodeBox(value: '•', isFilled: true),
                  _buildCodeBox(value: '•', isFilled: true),
                  _buildCodeBox(value: '8', isFilled: true),
                  _buildCodeBox(value: '', isFilled: false),
                ],
              ),

              SizedBox(height: 140.h),

              // Botón Siguiente
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/register-success');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D8DFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Siguiente',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget maqueta para cada casilla individual del código
  Widget _buildCodeBox({required String value, required bool isFilled}) {
    return Container(
      width: 70.w,
      height: 70.h,
      decoration: BoxDecoration(
        color: const Color(0xFF7CAEFF), // Color azul pastel del diseño
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: value == '•' ? 36.sp : 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
