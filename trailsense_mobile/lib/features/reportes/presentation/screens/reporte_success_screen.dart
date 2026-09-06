import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ReporteSuccessScreen extends StatelessWidget {
  const ReporteSuccessScreen({super.key});

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
                  width: 220.r, height: 220.r,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                  child: Center(
                    child: Container(
                      width: 160.r, height: 160.r,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                      child: Center(
                        child: Container(
                          width: 100.r, height: 100.r,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.check, color: const Color(0xFF3B82F6), size: 50.sp),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Text('¡Reporte enviado!', style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text('Gracias por ayudar a mantener seguros los senderos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14.sp)),
              const Spacer(flex: 5),
              SizedBox(
                width: double.infinity, height: 54.h,
                child: ElevatedButton(
                  onPressed: () => Get.offAllNamed('/mis-reportes'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5F7FA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                  child: Text('Volver al listado de reportes', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}