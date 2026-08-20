import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/register_controller.dart';

class RegisterFormScreen extends GetView<RegisterController> {
  const RegisterFormScreen({super.key});

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
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),

                // =========================================================
                // FOTO DE PERFIL
                // =========================================================
                Center(
                  child: Obx(() {
                    final File? foto = controller.fotoPerfil.value;

                    return GestureDetector(
                      onTap: controller.seleccionarFoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 52.r,
                            backgroundColor: const Color(0xFFE9F6FE),
                            backgroundImage: foto != null
                                ? FileImage(foto)
                                : null,
                            child: foto == null
                                ? Icon(
                                    Icons.person,
                                    size: 55.sp,
                                    color: const Color(0xFF4C8DFF),
                                  )
                                : null,
                          ),

                          Container(
                            width: 32.w,
                            height: 32.h,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4C8DFF),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

                SizedBox(height: 12.h),

                Center(
                  child: Text(
                    'Agregar foto de perfil',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                // =========================================================
                // SALUDO
                // =========================================================
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Hola ',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6C757D),
                      ),
                      children: [
                        TextSpan(
                          text: 'Senderista!',
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1D2A44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // =========================================================
                // NOMBRE
                // =========================================================
                _buildUnderlineTextField(
                  controller: controller.nombreCtrl,
                  hintText: 'Nombre',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }

                    if (value.trim().length < 2) {
                      return 'El nombre es demasiado corto';
                    }

                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // =========================================================
                // APELLIDO
                // =========================================================
                _buildUnderlineTextField(
                  controller: controller.apellidoCtrl,
                  hintText: 'Apellido',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu apellido';
                    }
                    if (value.trim().length < 2) {
                      return 'El apellido es demasiado corto';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // =========================================================
                // EMAIL
                // =========================================================
                _buildUnderlineTextField(
                  controller: controller.emailCtrl,
                  hintText: 'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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

                SizedBox(height: 24.h),

                // =========================================================
                // PASSWORD
                // =========================================================
                Obx(
                  () => _buildUnderlineTextField(
                    controller: controller.passwordCtrl,
                    hintText: 'Contraseña',
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

                // =========================================================
                // CONFIRMAR PASSWORD
                // =========================================================
                Obx(
                  () => _buildUnderlineTextField(
                    controller: controller.confirmPasswordCtrl,
                    hintText: 'Confirmar Contraseña',
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

                SizedBox(height: 48.h),

                // =========================================================
                // BOTÓN REGISTRARSE
                // =========================================================
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.registrar,
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
                              'Registrarse',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // =========================================================
                // LOGIN
                // =========================================================
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(
                          fontSize: 14.sp,
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
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFCC0000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
