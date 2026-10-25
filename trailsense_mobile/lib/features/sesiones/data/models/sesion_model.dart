import 'package:latlong2/latlong.dart';

class SesionModel {
  final int id;
  final int? numeroUsuario;
  final int? senderoId;
  final String? senderoNombre;
  final String estado;
  final DateTime iniciadoEn;
  final DateTime? finalizadoEn;
  final double distanciaKm;
  final int duracionSegundos;
  final double velocidadPromedioKmh;
  final int pasos;
  final LatLng? puntoInicio;
  final List<LatLng> traza;

  static const List<String> _diasSemana = <String>[
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  /// Día de la semana en que inició el recorrido (hora local del teléfono).
  String get diaSemana => _diasSemana[iniciadoEn.toLocal().weekday - 1];

  /// "Sendero Catamayo - Recorrido Jueves" o "Recorrido Libre Lunes".
  String get nombreMostrable {
    final String base = senderoNombre != null
        ? '$senderoNombre - Recorrido $diaSemana'
        : 'Recorrido Libre $diaSemana';
    return estado == 'finalizada' ? base : '$base (sin finalizar)';
  }

  SesionModel({
    required this.id,
    this.numeroUsuario,
    this.senderoId,
    this.senderoNombre,
    required this.estado,
    required this.iniciadoEn,
    this.finalizadoEn,
    required this.distanciaKm,
    required this.duracionSegundos,
    required this.velocidadPromedioKmh,
    required this.pasos,
    this.puntoInicio,
    this.traza = const [],
  });

  factory SesionModel.fromJson(Map<String, dynamic> json) {
    LatLng? inicio;
    if (json['punto_inicio'] != null) {
      inicio = LatLng(
        (json['punto_inicio']['lat'] as num).toDouble(),
        (json['punto_inicio']['lon'] as num).toDouble(),
      );
    }

    List<LatLng> trazaPuntos = [];
    if (json['traza'] != null) {
      trazaPuntos = (json['traza'] as List)
          .map<LatLng>((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList();
    }

    return SesionModel(
      id: json['id'],
      numeroUsuario: json['numero_usuario'],
      senderoId: json['sendero'],
      senderoNombre: json['sendero_nombre'],
      estado: json['estado'] ?? 'en_curso',
      iniciadoEn: DateTime.parse(json['iniciado_en']),
      finalizadoEn: json['finalizado_en'] != null ? DateTime.parse(json['finalizado_en']) : null,
      distanciaKm: (json['distancia_km'] ?? 0).toDouble(),
      duracionSegundos: json['duracion_segundos'] ?? 0,
      velocidadPromedioKmh: (json['velocidad_promedio_kmh'] ?? 0).toDouble(),
      pasos: json['pasos'] ?? 0,
      puntoInicio: inicio,
      traza: trazaPuntos,
    );
  }
}