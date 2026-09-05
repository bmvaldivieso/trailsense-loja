import '../../../../core/network/api_client.dart';
import '../models/sesion_model.dart';
import '../models/punto_gps_model.dart';

class SesionesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<SesionModel>> listarSesiones() async {
    final response = await _apiClient.dio.get('/sesiones/');
    final List data = response.data;
    return data.map((j) => SesionModel.fromJson(j)).toList();
  }

  Future<SesionModel> obtenerSesion(int id) async {
    final response = await _apiClient.dio.get('/sesiones/$id/');
    return SesionModel.fromJson(response.data);
  }

  Future<SesionModel> iniciarSesion({int? senderoId, double? lat, double? lon}) async {
    final response = await _apiClient.dio.post('/sesiones/iniciar/', data: {
      if (senderoId != null) 'sendero': senderoId,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
    });
    return SesionModel.fromJson(response.data);
  }

  Future<void> enviarPuntos(int sesionId, List<PuntoGpsLocal> puntos) async {
    await _apiClient.dio.post(
      '/sesiones/$sesionId/puntos/',
      data: puntos.map((p) => p.toJson()).toList(),
    );
  }

  Future<SesionModel> pausarSesion(int id) async {
    final response = await _apiClient.dio.post('/sesiones/$id/pausar/');
    return SesionModel.fromJson(response.data);
  }

  Future<SesionModel> reanudarSesion(int id) async {
    final response = await _apiClient.dio.post('/sesiones/$id/reanudar/');
    return SesionModel.fromJson(response.data);
  }

  Future<SesionModel> finalizarSesion(int id, {required int tiempoPausadoSegundos, required int pasos}) async {
    final response = await _apiClient.dio.post('/sesiones/$id/finalizar/', data: {
      'tiempo_pausado_segundos': tiempoPausadoSegundos,
      'pasos': pasos,
    });
    return SesionModel.fromJson(response.data);
  }
}