import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/metricas_model.dart';

class MesDisponible {
  final String valor;     // "2026-08"
  final String etiqueta;  // "Agosto 2026"
  MesDisponible(this.valor, this.etiqueta);
}

class MetricasRepository {
  final ApiClient _apiClient = ApiClient();

  Future<MetricasPersonalesModel> obtenerMetricas(String periodo, {String? mes}) async {
    final response = await _apiClient.dio.get('/metricas/personales/',
        queryParameters: {'periodo': periodo, if (mes != null) 'mes': mes});
    return MetricasPersonalesModel.fromJson(response.data);
  }

  Future<Uint8List> descargarPdf(String periodo, {String? mes}) async {
    final response = await _apiClient.dio.get(
      '/metricas/personales/pdf/',
      queryParameters: {'periodo': periodo, if (mes != null) 'mes': mes},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  Future<List<MesDisponible>> obtenerMeses() async {   // NUEVO
    final response = await _apiClient.dio.get('/metricas/personales/meses/');
    return (response.data as List).map((e) => MesDisponible(e['valor'], e['etiqueta'])).toList();
  }
}