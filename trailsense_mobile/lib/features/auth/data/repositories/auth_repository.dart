import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  Future<Response> login(String email, String password) {
    return _dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
  }
}