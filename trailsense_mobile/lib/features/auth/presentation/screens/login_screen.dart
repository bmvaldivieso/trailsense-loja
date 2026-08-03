import 'package:flutter/material.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. Título de bienvenida
              const Text(
                '¡Bienvenido de nuevo!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 36),

              // 2. Subtítulo botones sociales
              const Text(
                'Iniciar sesión con:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // 3. Botones Redes Sociales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SocialButton(
                    backgroundColor: const Color(0xFF3B5998),
                    child: const Text(
                      'f',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
                      height: 24,
                      errorBuilder: (_, __, ___) => const Text(
                        'G',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    onTap: () {},
                  ),
                  _SocialButton(
                    backgroundColor: Colors.white,
                    hasBorder: true,
                    child: const Icon(
                      Icons.phone,
                      color: Color(0xFF51B082),
                      size: 24,
                    ),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 4. Separador "o"
              const Center(
                child: Text(
                  'o',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 5. Campo de Correo Electrónico
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Correo electrónico',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4C8DFF)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 6. Campo de Contraseña
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Contraseña',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4C8DFF)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 7. Mensaje de Error Reactivo
              Obx(() => controller.errorMessage.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 24),

              // 8. Botón Iniciar Sesión / Spinner de Carga
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4C8DFF),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: controller.login, // Llama a la función de autenticación
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C8DFF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // 9. Enlace hacia Registrarse
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Get.toNamed('/register');
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                      children: [
                        TextSpan(text: '¿Necesitas una cuenta? '),
                        TextSpan(
                          text: 'Registrarse',
                          style: TextStyle(
                            color: Color(0xFFDC2626), // Rojo del diseño
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 95,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder
              ? Border.all(color: const Color(0xFFEEEEEE), width: 1.5)
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}