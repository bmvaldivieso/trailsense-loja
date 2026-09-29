class MesKm {
  final String mes;
  final double km;
  MesKm({required this.mes, required this.km});
}

class MetricasPersonalesModel {
  final String nombre;
  final String? fotoUrl;
  final double distanciaKm;
  final int pasos;
  final String tiempoTexto;
  final int reportes;
  final int recorridos;
  final String fechaRegistro;
  final String estado;
  final List<MesKm> mensuales;
  final double tiempoMovimientoH;
  final double distanciaVitaliciaKm;
  final double velocidadPromedioKmh;
  final int pctRecorridos;
  final int pctReportes;
  final int pctFotos;

  MetricasPersonalesModel({
    required this.nombre, this.fotoUrl, required this.distanciaKm, required this.pasos,
    required this.tiempoTexto, required this.reportes, required this.recorridos,
    required this.fechaRegistro, required this.estado, required this.mensuales,
    required this.tiempoMovimientoH, required this.distanciaVitaliciaKm, required this.velocidadPromedioKmh,
    required this.pctRecorridos, required this.pctReportes, required this.pctFotos,
  });

  factory MetricasPersonalesModel.fromJson(Map<String, dynamic> json) {
    final resumen = json['resumen'];
    final vitalicias = json['vitalicias'];
    final composicion = json['composicion'];

    return MetricasPersonalesModel(
      nombre: resumen['nombre'],
      fotoUrl: resumen['foto'],
      distanciaKm: (resumen['distancia_km'] ?? 0).toDouble(),
      pasos: resumen['pasos'] ?? 0,
      tiempoTexto: resumen['tiempo_texto'] ?? '0h 0min',
      reportes: resumen['reportes'] ?? 0,
      recorridos: resumen['recorridos'] ?? 0,
      fechaRegistro: resumen['fecha_registro'] ?? '',
      estado: resumen['estado'] ?? '',
      mensuales: (json['mensuales'] as List).map((m) => MesKm(mes: m['mes'], km: (m['km'] ?? 0).toDouble())).toList(),
      tiempoMovimientoH: (vitalicias['tiempo_movimiento_h'] ?? 0).toDouble(),
      distanciaVitaliciaKm: (vitalicias['distancia_km'] ?? 0).toDouble(),
      velocidadPromedioKmh: (vitalicias['velocidad_promedio_kmh'] ?? 0).toDouble(),
      pctRecorridos: composicion['recorridos'] ?? 0,
      pctReportes: composicion['reportes'] ?? 0,
      pctFotos: composicion['fotos'] ?? 0,
    );
  }
}