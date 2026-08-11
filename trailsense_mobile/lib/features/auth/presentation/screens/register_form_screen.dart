import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RegisterFormScreen extends StatelessWidget {
  const RegisterFormScreen({Key? key}) : super(key: key);

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
        // Se mantiene SingleChildScrollView: es necesario para que el formulario
        // no se desborde cuando, al implementar la funcionalidad, se agreguen
        // más campos (ej. fecha de nacimiento, género, etc.)
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),

              // Encabezado "Hola Senderista!"
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

              // Campo Nombre
              _buildUnderlineTextField(
                hintText: 'Nombre',
                keyboardType: TextInputType.name,
              ),

              SizedBox(height: 24.h),

              // Campo Correo electrónico
              _buildUnderlineTextField(
                hintText: 'Correo electrónico',
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 24.h),

              // Campo Contraseña
              _buildUnderlineTextField(
                hintText: 'Contraseña',
                obscureText: true,
              ),

              SizedBox(height: 24.h),

              // Campo Confirmar Contraseña
              _buildUnderlineTextField(
                hintText: 'Confirmar Contraseña',
                obscureText: true,
              ),

              SizedBox(height: 24.h),

              // Campo Código de país + Teléfono
              Row(
                children: [
                  SizedBox(
                    width: 90.w,
                    child: DropdownButtonFormField<String>(
                      value: '+880',
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20.sp,
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4285F4)),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '+880',
                          child: Text('+880'),
                        ),
                        DropdownMenuItem(
                          value: '+593',
                          child: Text('+593'),
                        ),
                      ],
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildUnderlineTextField(
                      hintText: 'Número de teléfono',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 48.h),

              // Botón Registrarse
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/verify-code');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C8DFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Registrarse',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Footer "¿Ya tienes cuenta? Iniciar Sesión"
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
                        // Se usa offAllNamed (igual que en register_screen.dart)
                        // para limpiar el stack de registro y evitar volver
                        // a un formulario incompleto con el botón atrás.
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
    );
  }

  Widget _buildUnderlineTextField({
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 15.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFFBDBDBD),
          fontSize: 15.sp,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4285F4)),
        ),
      ),
    );
  }
}
