class FotoReporteModel {
  final int id;
  final String url;
  final int orden;

  FotoReporteModel({required this.id, required this.url, required this.orden});

  factory FotoReporteModel.fromJson(Map<String, dynamic> json) {
    return FotoReporteModel(id: json['id'], url: json['imagen'], orden: json['orden'] ?? 0);
  }
}

class ReporteModel {
  final int id;
  final int senderoId;
  final String senderoNombre;
  final String usuarioEmail;
  final String categoria;
  final String descripcion;
  final bool validado;
  final int votosConfirmacion;
  final DateTime fechaCreacion;
  final String? fotoPortadaUrl;
  final double lat;
  final double lon;
  final double? altitud;
  final List<FotoReporteModel> fotos;

  ReporteModel({
    required this.id,
    required this.senderoId,
    required this.senderoNombre,
    required this.usuarioEmail,
    required this.categoria,
    required this.descripcion,
    required this.validado,
    required this.votosConfirmacion,
    required this.fechaCreacion,
    this.fotoPortadaUrl,
    required this.lat,
    required this.lon,
    this.altitud,
    this.fotos = const [],
  });

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    return ReporteModel(
      id: json['id'],
      senderoId: json['sendero'],
      senderoNombre: json['sendero_nombre'] ?? '',
      usuarioEmail: json['usuario_email'] ?? '',
      categoria: json['categoria'] ?? '',
      descripcion: json['descripcion'] ?? '',
      validado: json['validado'] ?? false,
      votosConfirmacion: json['votos_confirmacion'] ?? 0,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fotoPortadaUrl: json['foto_portada'],
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      altitud: json['altitud'] != null ? (json['altitud'] as num).toDouble() : null,
      fotos: json['fotos'] != null
          ? (json['fotos'] as List).map((f) => FotoReporteModel.fromJson(f)).toList()
          : [],
    );
  }
}