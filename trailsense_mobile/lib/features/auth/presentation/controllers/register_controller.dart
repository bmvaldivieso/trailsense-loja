import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../data/repositories/auth_repository.dart';

class RegisterController extends GetxController {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final AuthRepository authRepository = AuthRepository();

  // ============================================================
  // CONTROLLERS DEL FORMULARIO
  // ============================================================

  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  // ============================================================
  // CONTROLLERS Y FOCUS NODES PARA OTP (AGREGADOS)
  // ============================================================

  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(4, (_) => FocusNode());

  // ============================================================
  // FORMULARIO
  // ============================================================

  final formKey = GlobalKey<FormState>();

  // ============================================================
  // FOTO DE PERFIL
  // ============================================================

  final Rx<File?> fotoPerfil = Rx<File?>(null);
  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // ESTADOS REACTIVOS DE VALIDACIÓN
  // ============================================================

  final RxBool emailValido = false.obs;
  final RxBool passwordValida = false.obs;
  final RxBool passwordsCoinciden = false.obs;

    // ============================================================
  // VISIBILIDAD DE CONTRASEÑAS (AGREGADOS)
  // ============================================================

  final RxBool mostrarPassword = false.obs;
  final RxBool mostrarConfirmPassword = false.obs;

  void togglePassword() {
    mostrarPassword.value = !mostrarPassword.value;
  }

  void toggleConfirmPassword() {
    mostrarConfirmPassword.value = !mostrarConfirmPassword.value;
  }

  // ============================================================
  // ESTADOS GENERALES
  // ============================================================

  final RxBool isLoading = false.obs;

  // ============================================================
  // DATOS DEL FLUJO DE VERIFICACIÓN
  // ============================================================

  final RxString emailRegistrado = ''.obs;
  final RxString codigoIngresado = ''.obs;

  // ============================================================
  // TEMPORIZADOR (código completo — 15 minutos)
  // ============================================================

  static const int duracionCodigo = 15 * 60;
  final RxInt segundosRestantes = duracionCodigo.obs;
  Timer? _timer;

  // ============================================================
  // TEMPORIZADOR DE REENVÍO (cooldown corto)
  // ============================================================

  static const int duracionReenvio = 60; // 60 segundos
  final RxInt segundosParaReenviar = 0.obs;
  Timer? _timerReenvio;

  // ============================================================
  // CICLO DE VIDA
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    emailCtrl.addListener(_actualizarValidaciones);
    passwordCtrl.addListener(_actualizarValidaciones);
    confirmPasswordCtrl.addListener(_actualizarValidaciones);
  }

  // ============================================================
  // VALIDACIONES REACTIVAS
  // ============================================================

  void _actualizarValidaciones() {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;
    final confirmPassword = confirmPasswordCtrl.text;

    emailValido.value = GetUtils.isEmail(email);
    passwordValida.value = password.length >= 8;
    passwordsCoinciden.value =
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword;
  }

  bool validarFormulario() {
    _actualizarValidaciones();

    // Validar visualmente los campos en el Form
    if (formKey.currentState != null && !formKey.currentState!.validate()) {
      return false;
    }

    if (nombreCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa tu nombre.');
      return false;
    }

    if (apellidoCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa tu apellido.');
      return false;
    }

    if (!emailValido.value) {
      _mostrarError('Ingresa un correo electrónico válido.');
      return false;
    }

    if (!passwordValida.value) {
      _mostrarError('La contraseña debe tener al menos 8 caracteres.');
      return false;
    }

    if (!passwordsCoinciden.value) {
      _mostrarError('Las contraseñas no coinciden.');
      return false;
    }

    return true;
  }

  // ============================================================
  // MÉTODOS OTP (AGREGADOS)
  // ============================================================

  /// Actualiza el código completo ingresado y gestiona el cambio automático de foco
  void actualizarCodigo(int index, String value) {
    if (value.isNotEmpty) {
      // Si se escribió un dígito, avanza al siguiente campo
      if (index < 3) {
        otpFocusNodes[index + 1].requestFocus();
      } else {
        // Si es el último, quita el teclado
        otpFocusNodes[index].unfocus();
      }
    } else {
      // Si se borró, retrocede al campo anterior
      if (index > 0) {
        otpFocusNodes[index - 1].requestFocus();
      }
    }

    // Reconstruir el string del código concatenando los 4 inputs
    codigoIngresado.value =
        otpControllers.map((controller) => controller.text).join();
  }

  void _limpiarOtp() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    codigoIngresado.value = '';
  }

  // ============================================================
  // SELECCIONAR FOTO
  // ============================================================

  Future<void> seleccionarFoto() async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imagen != null) {
        fotoPerfil.value = File(imagen.path);
      }
    } catch (e) {
      _mostrarError('No se pudo seleccionar la imagen.');
    }
  }

  // ============================================================
  // REGISTRAR USUARIO
  // ============================================================

  Future<void> registrar() async {
    if (isLoading.value) return;

    if (!validarFormulario()) return;

    isLoading.value = true;

    try {
      final email = emailCtrl.text.trim();

      final response = await authRepository.register(
        nombre: nombreCtrl.text.trim(),
        apellido: apellidoCtrl.text.trim(),
        email: email,
        password: passwordCtrl.text,
        fotoPerfil: fotoPerfil.value,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        emailRegistrado.value = email;
        _limpiarOtp();
        iniciarTemporizador();
        iniciarCooldownReenvio();

        Get.toNamed('/verify-code');
      }
    } on DioException catch (e) {
      _mostrarError(_obtenerMensajeError(e));
    } catch (e) {
      _mostrarError(
        'No se pudo completar el registro. Intenta nuevamente.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // VERIFICAR CÓDIGO
  // ============================================================

  Future<void> verificarCodigo() async {
    if (isLoading.value) return;

    final codigo = codigoIngresado.value.trim();

    if (codigo.length != 4) {
      _mostrarError('Ingresa el código completo de 4 dígitos.');
      return;
    }

    if (emailRegistrado.value.isEmpty) {
      _mostrarError(
        'No se encontró el correo asociado al registro.',
      );
      return;
    }

    isLoading.value = true;

    try {
      final verificado = await authRepository.verifyCode(
        email: emailRegistrado.value,
        codigo: codigo,
      );

      if (verificado) {
        detenerTemporizador();
        Get.toNamed('/register-success');
      }
    } on DioException catch (e) {
      _mostrarError(_obtenerMensajeError(e));
    } catch (e) {
      _mostrarError('No se pudo verificar el código. Intenta nuevamente.');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // REENVIAR CÓDIGO
  // ============================================================

    Future<void> reenviarCodigo() async {
    if (isLoading.value) return;

    if (emailRegistrado.value.isEmpty) {
      _mostrarError('No se encontró el correo asociado al registro.');
      return;
    }

    if (segundosParaReenviar.value > 0) return;

    isLoading.value = true;

    try {
      final response = await authRepository.resendCode(
        email: emailRegistrado.value,
      );

      if (response.statusCode == 200) {
        _limpiarOtp();
        iniciarTemporizador();
        iniciarCooldownReenvio();

        _mostrarExito('Se ha enviado un nuevo código de verificación a tu correo.');
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
  // TEMPORIZADOR
  // ============================================================

  void iniciarTemporizador() {
    detenerTemporizador();
    segundosRestantes.value = duracionCodigo;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (segundosRestantes.value > 0) {
          segundosRestantes.value--;
        } else {
          detenerTemporizador();
        }
      },
    );
  }

  void detenerTemporizador() {
    _timer?.cancel();
    _timer = null;
  }

  // ============================================================
  // TEMPORIZADOR DE REENVÍO
  // ============================================================

  void iniciarCooldownReenvio() {
    _timerReenvio?.cancel();
    segundosParaReenviar.value = duracionReenvio;

    _timerReenvio = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (segundosParaReenviar.value > 0) {
          segundosParaReenviar.value--;
        } else {
          _timerReenvio?.cancel();
          _timerReenvio = null;
        }
      },
    );
  }

  void detenerCooldownReenvio() {
    _timerReenvio?.cancel();
    _timerReenvio = null;
  }

  // ============================================================
  // FORMATO DEL TEMPORIZADOR
  // ============================================================

  String get tiempoRestanteFormateado {
    final minutos = segundosRestantes.value ~/ 60;
    final segundos = segundosRestantes.value % 60;

    return '${minutos.toString().padLeft(2, '0')}:'
        '${segundos.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MENSAJES DE ERROR
  // ============================================================

    String _obtenerMensajeError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final mensajePorCodigo = _mensajeSegunCodigo(data['error']);
      if (mensajePorCodigo != null) {
        return mensajePorCodigo;
      }

      final mensaje = data['message'] ?? data['detail'];
      if (mensaje is String && mensaje.isNotEmpty) {
        return mensaje;
      }
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor.';
    }

    return 'Ocurrió un error. Intenta nuevamente.';
  }

  String? _mensajeSegunCodigo(dynamic errorCode) {
    switch (errorCode) {
      case 'email_already_registered':
        return 'Este correo ya está registrado.';
      case 'invalid_code':
        return 'El código ingresado no es correcto.';
      case 'code_already_used':
        return 'Este código ya no es válido. Solicita uno nuevo.';
      case 'code_expired':
        return 'El código expiró. Solicita uno nuevo.';
      case 'code_not_found':
        return 'No existe un código de verificación activo. Solicita uno nuevo.';
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

  void _mostrarExito(String mensaje) {
    Get.snackbar(
      'Listo',
      mensaje,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFFE9F6FE),
      colorText: const Color(0xFF3C80F7),
      icon: const Icon(Icons.check_circle_outline, color: Color(0xFF3C80F7)),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  // ============================================================
  // LIMPIEZA
  // ============================================================

  @override
  void onClose() {
    detenerTemporizador();
    detenerCooldownReenvio();

    emailCtrl.removeListener(_actualizarValidaciones);
    passwordCtrl.removeListener(_actualizarValidaciones);
    confirmPasswordCtrl.removeListener(_actualizarValidaciones);

    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();

    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
    }

    super.onClose();
  }
}