import '../../../../core/network/api_client.dart';
import '../models/notificacion_model.dart';

class NotificacionesRepository {
  final ApiClient _api = ApiClient();

  Future<ListadoNotificaciones> listar() async {
    final r = await _api.dio.get('/notificaciones/');
    final data = r.data as Map<String, dynamic>;
    return ListadoNotificaciones(
      items: (data['notificaciones'] as List).map((j) => NotificacionModel.fromJson(j)).toList(),
      noLeidas: data['no_leidas'] ?? 0,
    );
  }

  Future<NotificacionModel> obtener(int id) async {
    final r = await _api.dio.get('/notificaciones/$id/');
    return NotificacionModel.fromJson(r.data);
  }

  /// Devuelve la notificación creada, o null si no corresponde avisar.
  Future<NotificacionModel?> verificarProximidad(double lat, double lon) async {
    final r = await _api.dio.post('/notificaciones/proximidad/', data: {'lat': lat, 'lon': lon});
    final j = r.data['notificacion'];
    return j == null ? null : NotificacionModel.fromJson(j);
  }
}