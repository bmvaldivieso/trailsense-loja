import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  // =========================
  // LOGIN
  // =========================

  Future<Response> login(String email, String password) {
    return _dio.post(
      '/auth/login/',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  // =========================
  // REGISTRO
  // =========================

  Future<Response> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    File? fotoPerfil,
  }) async {
    final formData = FormData.fromMap({
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'password': password,
      'password2': password,
    });

    if (fotoPerfil != null) {
      formData.files.add(
        MapEntry(
          'foto_perfil',
          await MultipartFile.fromFile(
            fotoPerfil.path,
            filename: fotoPerfil.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }

    return _dio.post(
      '/auth/register/',
      data: formData,
    );
  }

  // =========================
  // VERIFICAR CÓDIGO
  // =========================

  Future<bool> verifyCode({
    required String email,
    required String codigo,
  }) async {
    final response = await _dio.post(
      '/auth/verify-code/',
      data: {
        'email': email,
        'codigo': codigo,
      },
    );

    return response.statusCode == 200 &&
        response.data['verified'] == true;
  }

  // =========================
  // REENVIAR CÓDIGO
  // =========================

  Future<Response> resendCode({
    required String email,
  }) {
    return _dio.post(
      '/auth/resend-code/',
      data: {
        'email': email,
      },
    );
  }
}