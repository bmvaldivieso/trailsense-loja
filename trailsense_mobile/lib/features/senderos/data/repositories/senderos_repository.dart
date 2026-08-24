import '../../../../core/network/api_client.dart';
import '../models/sendero_model.dart';

class SenderosRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<SenderoModel>> listarSenderos({
    String? dificultad,
    String? estado,
    double? longitudMin,
    double? longitudMax,
    double? lat,
    double? lon,
    double? radioKm,
  }) async {
    final Map<String, dynamic> query = {
      if (dificultad != null) 'dificultad': dificultad,
      if (estado != null) 'estado': estado,
      if (longitudMin != null) 'longitud_min': longitudMin.toString(),
      if (longitudMax != null) 'longitud_max': longitudMax.toString(),
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
      if (radioKm != null) 'radio_km': radioKm.toString(),
    };

    final response = await _apiClient.dio.get('/senderos/', queryParameters: query);

    final data = response.data;
    final List features = data is Map && data.containsKey('features')
        ? data['features'] as List
        : (data as List);

    return features
        .map((f) => SenderoModel.fromFeature(f as Map<String, dynamic>))
        .toList();
  }

  Future<SenderoModel> obtenerSendero(int id) async {
    final response = await _apiClient.dio.get('/senderos/$id/');
    return SenderoModel.fromFeature(response.data as Map<String, dynamic>);
  }
}