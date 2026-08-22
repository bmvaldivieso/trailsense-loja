import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/usuario_model.dart';

class PerfilRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UsuarioModel> obtenerPerfil() async {
    final response = await _apiClient.get('/auth/perfil/');
    return UsuarioModel.fromJson(response.data);
  }

  Future<UsuarioModel> actualizarPerfil({
    String? nombre,
    String? apellido,
    String? cedula,
    String? telefono,
    String? genero,
    DateTime? fechaNacimiento,
    File? fotoPerfil,
  }) async {
    final campos = <String, String>{
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (cedula != null) 'cedula': cedula,
      if (telefono != null) 'telefono': telefono,
      if (genero != null) 'genero': genero,
      if (fechaNacimiento != null)
        'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
    };

    final response = await _apiClient.patchMultipart(
      '/auth/perfil/',
      fields: campos,
      file: fotoPerfil,
      fileFieldName: 'foto_perfil',
    );

    return UsuarioModel.fromJson(response.data);
  }
}