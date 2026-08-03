import 'package:dio/dio.dart';

class ApiClient {
  // Emulador Android
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Dispositivo físico
  static const String baseUrl = 'http://192.168.100.42:8000/api';

  final Dio dio = Dio(BaseOptions(baseUrl: baseUrl));
}