import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/reporte_model.dart';

class ReportesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ReporteModel>> listarReportes({
    bool soloMios = false,
    String? categoria,
    int? senderoId,
  }) async {
    final response = await _apiClient.dio.get('/reportes/', queryParameters: {
      if (soloMios) 'mios': 'true',
      if (categoria != null) 'categoria': categoria,
      if (senderoId != null) 'sendero': senderoId,
    });
    final List data = response.data;
    return data.map((j) => ReporteModel.fromJson(j)).toList();
  }

  Future<ReporteModel> obtenerReporte(int id) async {
    final response = await _apiClient.dio.get('/reportes/$id/');
    return ReporteModel.fromJson(response.data);
  }

  Future<ReporteModel> crearReporte({
    required int senderoId,
    required double lat,
    required double lon,
    double? altitud,
    required String categoria,
    required String descripcion,
    required List<File> fotos,
  }) async {
    final formData = FormData.fromMap({
      'sendero': senderoId,
      'lat': lat,
      'lon': lon,
      if (altitud != null) 'altitud': altitud,
      'categoria': categoria,
      'descripcion': descripcion,
      'fotos': await Future.wait(
        fotos.map((f) => MultipartFile.fromFile(
              f.path,
              filename: f.path.split(Platform.pathSeparator).last,
            )),
      ),
    });

    final response = await _apiClient.dio.post('/reportes/crear/', data: formData);
    return ReporteModel.fromJson(response.data);
  }

  Future<List<ReporteModel>> buscarSimilares({
    required int senderoId,
    required String categoria,
    required double lat,
    required double lon,
  }) async {
    final response = await _apiClient.dio.get('/reportes/similares/', queryParameters: {
      'sendero': senderoId,
      'categoria': categoria,
      'lat': lat,
      'lon': lon,
    });
    final List data = response.data;
    return data.map((j) => ReporteModel.fromJson(j)).toList();
  }

  Future<int> votarReporte({
    required int reporteId,
    required double lat,
    required double lon,
  }) async {
    final response = await _apiClient.dio.post('/reportes/$reporteId/votar/', data: {'lat': lat, 'lon': lon});
    return response.data['votos_confirmacion'] as int;
  }
}