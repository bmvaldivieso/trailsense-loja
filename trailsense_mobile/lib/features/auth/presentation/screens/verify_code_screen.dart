import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/register_controller.dart';

class VerifyCodeScreen extends GetView<RegisterController> {
  const VerifyCodeScreen({super.key});

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

              // ===========================================================
              // TÍTULO
              // ===========================================================
              Text(
                'Introduce el código de\nactivación',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2B2B2B),
                  height: 1.2,
                ),
              ),

              SizedBox(height: 12.h),

              Text(
                'Ingresa el código de 4 dígitos enviado a tu correo.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),

              SizedBox(height: 16.h),

              // ===========================================================
              // CONTADOR
              // ===========================================================
              Obx(
                () {
                  final segundos = controller.segundosRestantes.value;
                  final minutos = segundos ~/ 60;
                  final segundosRestantes = segundos % 60;

                  final tiempo = '${minutos.toString().padLeft(2, '0')}:'
                      '${segundosRestantes.toString().padLeft(2, '0')}';

                  return Text(
                    segundos > 0
                        ? 'El código expira en $tiempo'
                        : 'El código ha expirado',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: segundos > 0
                          ? const Color(0xFF4C8DFF)
                          : Colors.red,
                    ),
                  );
                },
              ),

              SizedBox(height: 32.h),

              // ===========================================================
              // CAMPOS OTP
              // ===========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (index) => _buildCodeField(
                    index: index,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // ===========================================================
              // REENVIAR
              // ===========================================================

              Obx(
                () {
                  final puedeReenviar =
                      controller.segundosParaReenviar.value <= 0;

                  return Center(
                    child: TextButton(
                      onPressed: puedeReenviar
                          ? controller.reenviarCodigo
                          : null,
                      child: Text(
                        puedeReenviar
                            ? 'Reenviar código'
                            : 'Reenviar en ${controller.segundosParaReenviar.value}s',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: puedeReenviar
                              ? const Color(0xFF4C8DFF)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // ===========================================================
              // BOTÓN SIGUIENTE
              // ===========================================================
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.verificarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D8DFF),
                      disabledBackgroundColor:
                          const Color(0xFF9DBFFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Siguiente',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField({
    required int index,
  }) {
    return SizedBox(
      width: 70.w,
      height: 70.h,
      child: TextField(
        controller: controller.otpControllers[index],
        focusNode: controller.otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF7CAEFF),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: const BorderSide(
              color: Color(0xFF4C8DFF),
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          controller.actualizarCodigo(index, value);
        },
      ),
    );
  }
}