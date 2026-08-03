import 'package:get_storage/get_storage.dart';

class TokenStorage {
  final _box = GetStorage();

  // Guardar tokens
  void saveTokens(String access, String refresh) {
    _box.write('access_token', access);
    _box.write('refresh_token', refresh);
  }

  // Lectura de tokens
  String? get accessToken => _box.read<String>('access_token');
  String? get refreshToken => _box.read<String>('refresh_token');

  // Comprobar si existe un token guardado (útil para el Splash)
  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  // Borrar tokens (Cerrar sesión)
  void clear() => _box.erase();
}