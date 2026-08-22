import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../data/repositories/auth_repository.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository authRepository = AuthRepository();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final emailCtrl = TextEditingController();
  final codigoCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final formKeyEmail = GlobalKey<FormState>();
  final formKeyReset = GlobalKey<FormState>();

  // ============================================================
  // ESTADOS
  // ============================================================

  final RxBool codigoSolicitado = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool mostrarPassword = false.obs;
  final RxBool mostrarConfirmPassword = false.obs;

  void togglePassword() => mostrarPassword.value = !mostrarPassword.value;
  void toggleConfirmPassword() =>
      mostrarConfirmPassword.value = !mostrarConfirmPassword.value;

  // ============================================================
  // COOLDOWN DE REENVÍO
  // ============================================================

  static const int duracionReenvio = 60;
  final RxInt segundosParaReenviar = 0.obs;
  Timer? _timerReenvio;

  void _iniciarCooldown() {
    _timerReenvio?.cancel();
    segundosParaReenviar.value = duracionReenvio;

    _timerReenvio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosParaReenviar.value > 0) {
        segundosParaReenviar.value--;
      } else {
        _timerReenvio?.cancel();
        _timerReenvio = null;
      }
    });
  }

  // ============================================================
  // SOLICITAR CÓDIGO
  // ============================================================

  Future<void> solicitarCodigo() async {
    if (isLoading.value) return;

    if (formKeyEmail.currentState == null ||
        !formKeyEmail.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final response = await authRepository.requestPasswordReset(
        email: emailCtrl.text.trim(),
      );

      if (response.statusCode == 200) {
        codigoSolicitado.value = true;
        _iniciarCooldown();

        Get.snackbar(
          'Código enviado',
          'Revisa tu correo para continuar con la recuperación.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } on DioException catch (e) {
      _mostrarError(_obtenerMensajeError(e));
    } catch (e) {
      _mostrarError('No se pudo enviar el código. Intenta nuevamente.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reenviarCodigo() async {
    if (segundosParaReenviar.value > 0 || isLoading.value) return;

    isLoading.value = true;

    try {
      final response = await authRepository.requestPasswordReset(
        email: emailCtrl.text.trim(),
      );

      if (response.statusCode == 200) {
        _iniciarCooldown();

        Get.snackbar(
          'Código reenviado',
          'Se ha enviado un nuevo código a tu correo.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } on DioException catch (e) {
      _mostrarError(_obtenerMensajeError(e));
    } catch (e) {
      _mostrarError('No se pudo reenviar el código. Intenta nuevamente.');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // CONFIRMAR NUEVA CONTRASEÑA
  // ============================================================

  Future<void> restablecerContrasena() async {
    if (isLoading.value) return;

    if (formKeyReset.currentState == null ||
        !formKeyReset.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final response = await authRepository.resetPassword(
        email: emailCtrl.text.trim(),
        codigo: codigoCtrl.text.trim(),
        password: passwordCtrl.text,
        password2: confirmPasswordCtrl.text,
      );

      if (response.statusCode == 200) {
        _timerReenvio?.cancel();
        Get.offNamed('/password-reset-success');
      }
    } on DioException catch (e) {
      _mostrarError(_obtenerMensajeError(e));
    } catch (e) {
      _mostrarError(
        'No se pudo restablecer la contraseña. Intenta nuevamente.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // MANEJO DE ERRORES (mismo patrón que RegisterController)
  // ============================================================

  String _obtenerMensajeError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final codigo = _mensajeSegunCodigo(data['error']);
      if (codigo != null) return codigo;

      final mensaje = data['message'] ?? data['detail'];
      if (mensaje is String && mensaje.isNotEmpty) return mensaje;
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor.';
    }

    return 'Ocurrió un error. Intenta nuevamente.';
  }

  String? _mensajeSegunCodigo(dynamic errorCode) {
    switch (errorCode) {
      case 'user_not_found':
        return 'No existe un usuario registrado con ese correo.';
      case 'invalid_code':
        return 'El código ingresado no es correcto.';
      case 'code_already_used':
        return 'Este código ya no es válido. Solicita uno nuevo.';
      case 'code_expired':
        return 'El código expiró. Solicita uno nuevo.';
      default:
        return null;
    }
  }

  void _mostrarError(String mensaje) {
    Get.snackbar(
      'Error',
      mensaje,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFFFDEDED),
      colorText: const Color(0xFFB3261E),
      icon: const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  // ============================================================
  // LIMPIEZA
  // ============================================================

  @override
  void onClose() {
    _timerReenvio?.cancel();
    emailCtrl.dispose();
    codigoCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
