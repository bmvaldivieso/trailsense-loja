import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Obx(
            () => controller.codigoSolicitado.value
                ? _buildFormRestablecer()
                : _buildFormEmail(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FASE 1: PEDIR CORREO
  // ============================================================

  Widget _buildFormEmail() {
    return Form(
      key: controller.formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30.h),

          Text(
            '¿Olvidaste tu\ncontraseña?',
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2B2B2B),
              height: 1.2,
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            'Ingresa el correo con el que te registraste y te enviaremos un código de recuperación.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),

          SizedBox(height: 40.h),

          _buildUnderlineTextField(
            controller: controller.emailCtrl,
            hintText: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu correo';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),

          SizedBox(height: 48.h),

          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.solicitarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C8DFF),
                  disabledBackgroundColor: const Color(0xFF9DBFFF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
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
                        'Enviar código',
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
    );
  }

  // ============================================================
  // FASE 2: CÓDIGO + NUEVA CONTRASEÑA
  // ============================================================

  Widget _buildFormRestablecer() {
    return Form(
      key: controller.formKeyReset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30.h),

          Text(
            'Restablece tu\ncontraseña',
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2B2B2B),
              height: 1.2,
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            'Ingresa el código de 4 dígitos enviado a ${controller.emailCtrl.text.trim()} y tu nueva contraseña.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),

          SizedBox(height: 32.h),

          _buildUnderlineTextField(
            controller: controller.codigoCtrl,
            hintText: 'Código de 4 dígitos',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().length != 4) {
                return 'Ingresa el código completo de 4 dígitos';
              }
              return null;
            },
          ),

          SizedBox(height: 24.h),

          Obx(
            () => _buildUnderlineTextField(
              controller: controller.passwordCtrl,
              hintText: 'Nueva contraseña',
              obscureText: !controller.mostrarPassword.value,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.mostrarPassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: controller.togglePassword,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una contraseña';
                }
                if (value.length < 8) {
                  return 'Mínimo 8 caracteres';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: 24.h),

          Obx(
            () => _buildUnderlineTextField(
              controller: controller.confirmPasswordCtrl,
              hintText: 'Confirmar nueva contraseña',
              obscureText: !controller.mostrarConfirmPassword.value,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.mostrarConfirmPassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: controller.toggleConfirmPassword,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu contraseña';
                }
                if (value != controller.passwordCtrl.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: 16.h),

          Obx(
            () {
              final puedeReenviar = controller.segundosParaReenviar.value <= 0;
              return Center(
                child: TextButton(
                  onPressed: puedeReenviar ? controller.reenviarCodigo : null,
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

          SizedBox(height: 32.h),

          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.restablecerContrasena,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C8DFF),
                  disabledBackgroundColor: const Color(0xFF9DBFFF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
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
                        'Restablecer contraseña',
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
    );
  }

  // ============================================================
  // CAMPO REUTILIZABLE (mismo estilo que RegisterFormScreen)
  // ============================================================

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: TextStyle(fontSize: 15.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: const Color(0xFFBDBDBD), fontSize: 15.sp),
        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        suffixIcon: suffixIcon,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4285F4)),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}