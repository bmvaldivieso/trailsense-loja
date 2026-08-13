import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/storage/token_storage.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final TokenStorage _tokenStorage = TokenStorage();

  // Controladores para los campos de texto
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Estados reactivos
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> login() async {
    errorMessage.value = '';

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Ingresa tu correo y contraseña.';
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authRepository.login(email, password);
      
      // Guarda los tokens JWT de acceso y refresco
      _tokenStorage.saveTokens(
        response.data['access'], 
        response.data['refresh'],
      );

      // Redirige al Main mediante ruta nombrada (recomendado con GetX)
      Get.offAllNamed('/main');
    } catch (_) {
      errorMessage.value = 'Credenciales incorrectas.';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}