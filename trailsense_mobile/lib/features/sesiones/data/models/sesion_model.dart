import 'package:latlong2/latlong.dart';

class SesionModel {
  final int id;
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

  SesionModel({
    required this.id,
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