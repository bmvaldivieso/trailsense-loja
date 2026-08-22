class UsuarioModel {
  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final String rol;
  final String? fotoPerfilUrl;
  final DateTime? fechaRegistro;
  final int totalReportes;
  final double totalKmRecorridos;
  final double reputacionScore;
  final bool isVerified;

  // Campos nuevos Sprint 5
  final String? cedula;
  final String? telefono;
  final String? genero;
  final DateTime? fechaNacimiento;

  UsuarioModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    this.fotoPerfilUrl,
    this.fechaRegistro,
    required this.totalReportes,
    required this.totalKmRecorridos,
    required this.reputacionScore,
    required this.isVerified,

    // Campos nuevos Sprint 5
    this.cedula,
    this.telefono,
    this.genero,
    this.fechaNacimiento,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      rol: json['rol'] ?? '',
      fotoPerfilUrl: json['foto_perfil_url'],
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'])
          : null,
      totalReportes: json['total_reportes'] ?? 0,
      totalKmRecorridos:
          (json['kilometros_recorridos'] ?? 0).toDouble(),
      reputacionScore:
          (json['reputacion_score'] ?? 0).toDouble(),
      isVerified: json['is_verified'] ?? false,

      // Campos nuevos Sprint 5
      cedula: json['cedula'],
      telefono: json['telefono'],
      genero: json['genero'],
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.tryParse(json['fecha_nacimiento'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'rol': rol,
      'foto_perfil_url': fotoPerfilUrl,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'total_reportes': totalReportes,
      'kilometros_recorridos': totalKmRecorridos,
      'reputacion_score': reputacionScore,
      'is_verified': isVerified,

      // Campos nuevos Sprint 5
      'cedula': cedula,
      'telefono': telefono,
      'genero': genero,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
    };
  }
}