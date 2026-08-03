class UsuarioModel {
  final int id;
  final String email;
  final String nombre;
  final String rol;

  UsuarioModel({required this.id, required this.email, required this.nombre, required this.rol});

  factory UsuarioModel.fromJson(Map<String, dynamic> json) => UsuarioModel(
    id: json['id'],
    email: json['email'],
    nombre: json['nombre'] ?? '',
    rol: json['rol'] ?? '',
  );
}