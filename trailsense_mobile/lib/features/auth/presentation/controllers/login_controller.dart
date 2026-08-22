import 'package:dio/dio.dart';
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
      _tokenStorage.saveTokens(
        response.data['access'],
        response.data['refresh'],
      );
      Get.offAllNamed('/main');
    } on DioException catch (e) {
      errorMessage.value = _obtenerMensajeError(e);
    } catch (e) {
      errorMessage.value = 'Ocurrió un error. Intenta nuevamente.';
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // MANEJO DE ERRORES
  // ============================================================

  String _obtenerMensajeError(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Credenciales incorrectas.';
    }

    if (error.type == DioExceptionType.badCertificate) {
      return 'No se pudo verificar la conexión segura con el servidor.';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'No se pudo conectar con el servidor. Verifica tu conexión.';
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final mensaje = data['detail'] ?? data['message'];
      if (mensaje is String && mensaje.isNotEmpty) return mensaje;
    }

    return 'Ocurrió un error. Intenta nuevamente.';
  }

  // ============================================================
  // LIMPIEZA DE CAMPOS LOGIN
  // ============================================================

  void limpiarCampos() {
    emailController.clear();
    passwordController.clear();
    errorMessage.value = '';
  }
}
