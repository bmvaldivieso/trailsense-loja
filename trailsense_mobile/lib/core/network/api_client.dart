import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import '../storage/token_storage.dart';

class ApiClient {
  // Emulador Android
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Dispositivo físico
  // static const String baseUrl = 'http://192.168.100.42:8000/api';

  // Dispositivo físico con HTTPS
  static const String baseUrl = 'https://192.168.100.42:8000/api';

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  ApiClient() {
    _configurarCertificadoLocal();
    _configurarInterceptorToken();
  }

  // Agrega el token JWT automáticamente a cada petición
  void _configurarInterceptorToken() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage().accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<void> _configurarCertificadoLocal() async {
    try {
      final ByteData data = await rootBundle.load('assets/certs/rootCA.pem');
      final SecurityContext context = SecurityContext(withTrustedRoots: true);
      context.setTrustedCertificatesBytes(data.buffer.asUint8List());

      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient(context: context);
        return client;
      };
    } catch (e) {
      // ignore: avoid_print
      print('[WARN] No se pudo cargar el certificado local de desarrollo: $e');
    }
  }

  Future<Response> get(String endpoint) async {
    return await dio.get(endpoint);
  }

  Future<Response> patchMultipart(
    String endpoint, {
    required Map<String, String> fields,
    File? file,
    String? fileFieldName,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      if (file != null && fileFieldName != null)
        fileFieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
    });

    return await dio.patch(
      endpoint,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }
}