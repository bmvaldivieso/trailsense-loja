import 'package:latlong2/latlong.dart';

class SenderoModel {
  final int id;
  final String nombre;
  final String descripcion;
  final String canton;
  final String dificultad;
  final String estado;
  final double longitudKm;
  final String? horarioApertura;
  final String? horarioCierre;
  final String? imagenPortadaUrl;
  final List<LatLng> puntos;

  SenderoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.canton,
    required this.dificultad,
    required this.estado,
    required this.longitudKm,
    this.horarioApertura,
    this.horarioCierre,
    this.imagenPortadaUrl,
    required this.puntos,
  });

  LatLng get puntoInicio => puntos.isNotEmpty ? puntos.first : const LatLng(-3.9973, -79.2005);

  factory SenderoModel.fromFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometryRaw = feature['geometry'];

    final List<LatLng> puntos = _parsearGeometria(geometryRaw);

    return SenderoModel(
      id: feature['id'] ?? properties['id'] ?? 0,
      nombre: properties['nombre'] ?? '',
      descripcion: properties['descripcion'] ?? '',
      canton: properties['canton'] ?? '',
      dificultad: properties['dificultad'] ?? '',
      estado: properties['estado'] ?? '',
      longitudKm: (properties['longitud_km'] ?? 0).toDouble(),
      horarioApertura: properties['horario_apertura'],
      horarioCierre: properties['horario_cierre'],
      imagenPortadaUrl: properties['imagen_portada'],
      puntos: puntos,
    );
  }

  // Maneja tanto GeoJSON (Map) como WKT/EWKT (String)
  static List<LatLng> _parsearGeometria(dynamic geometryRaw) {
    if (geometryRaw == null) return [];

    // Caso 1: viene como GeoJSON normal { "type": "LineString", "coordinates": [...] }
    if (geometryRaw is Map<String, dynamic>) {
      if (geometryRaw['type'] != 'LineString') return [];
      final coords = geometryRaw['coordinates'] as List;
      return coords.map<LatLng>((p) {
        return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
      }).toList();
    }

    // Caso 2: viene como WKT o EWKT en texto, ej:
    // "SRID=4326;LINESTRING (-79.2 -3.9, -79.19 -3.98)" o "LINESTRING (-79.2 -3.9, ...)"
    if (geometryRaw is String) {
      final match = RegExp(r'LINESTRING\s*\(([^)]+)\)', caseSensitive: false)
          .firstMatch(geometryRaw);
      if (match == null) return [];

      final coordenadasTexto = match.group(1)!.trim();
      return coordenadasTexto.split(',').map<LatLng>((par) {
        final partes = par.trim().split(RegExp(r'\s+')).map(double.parse).toList();
        return LatLng(partes[1], partes[0]);   // lon lat -> LatLng(lat, lon)
      }).toList();
    }

    return [];
  }
}