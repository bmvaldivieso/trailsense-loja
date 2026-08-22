import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56.h,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 28.r,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 28.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // 1. Título de bienvenida
              Text(
                '¡Bienvenido de nuevo!',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 36.h),

              // 2. Subtítulo botones sociales
              Text(
                'Iniciar sesión con:',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 16.h),

              // 3. Botones Redes Sociales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SocialButton(
                    backgroundColor: const Color(0xFF3B5998),
                    child: Text(
                      'f',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {},
                  ),

                  _SocialButton(
                    backgroundColor: Colors.white,
                    hasBorder: true,
                    child: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                      height: 24.h,
                      errorBuilder: (_, __, ___) => Text(
                        'G',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                    onTap: () {},
                  ),

                  _SocialButton(
                    backgroundColor: Colors.white,
                    hasBorder: true,
                    child: Icon(
                      Icons.phone,
                      color: const Color(0xFF51B082),
                      size: 24.r,
                    ),
                    onTap: () {},
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // 4. Separador "o"
              Center(
                child: Text(
                  'o',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16.sp,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // 5. Campo de Correo Electrónico
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16.sp,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF4C8DFF),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // 6. Campo de Contraseña
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16.sp,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF4C8DFF),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // Enlace a recuperación de contraseña
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Get.toNamed('/forgot-password'),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4C8DFF),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),

              // 7. Mensaje de Error Reactivo
              Obx(
                () => controller.errorMessage.value.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(
                          bottom: 8.h,
                        ),
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              SizedBox(height: 24.h),

              // 8. Botón Iniciar Sesión / Spinner de Carga
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: Obx(
                  () => controller.isLoading.value
                      ? Center(
                          child: SizedBox(
                            width: 24.r,
                            height: 24.r,
                            child: const CircularProgressIndicator(
                              color: Color(0xFF4C8DFF),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: controller.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF4C8DFF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Iniciar Sesión',
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

              // 9. Enlace hacia Registrarse
              Center(
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed('/register');
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(
                          text: '¿Necesitas una cuenta? ',
                        ),
                        TextSpan(
                          text: 'Registrarse',
                          style: TextStyle(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
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
}

// Widget auxiliar privado para los botones sociales
class _SocialButton extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final bool hasBorder;
  final VoidCallback onTap;

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
        width: 95.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: hasBorder
              ? Border.all(
                  color: const Color(0xFFEEEEEE),
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}