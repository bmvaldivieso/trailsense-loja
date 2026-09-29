import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/metricas_model.dart';

class MetricasRepository {
  final ApiClient _apiClient = ApiClient();

  Future<MetricasPersonalesModel> obtenerMetricas(String periodo) async {
    final response = await _apiClient.dio.get('/metricas/personales/', queryParameters: {'periodo': periodo});
    return MetricasPersonalesModel.fromJson(response.data);
  }

  Future<Uint8List> descargarPdf(String periodo) async {
    final response = await _apiClient.dio.get(
      '/metricas/personales/pdf/',
      queryParameters: {'periodo': periodo},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}