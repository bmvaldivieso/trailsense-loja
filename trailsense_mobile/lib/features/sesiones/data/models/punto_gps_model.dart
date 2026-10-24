class PuntoGpsLocal {
  final double lat;
  final double lon;
  final DateTime capturadoEn;
  final double? precisionM;
  final double? altitudM;
  final double? velocidadMps;
  final bool iniciaTramo;

  PuntoGpsLocal({
    required this.lat,
    required this.lon,
    required this.capturadoEn,
    this.precisionM,
    this.altitudM,
    this.velocidadMps,
    this.iniciaTramo = false,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'capturado_en': capturadoEn.toIso8601String(),
        if (precisionM != null) 'precision_m': precisionM,
        if (altitudM != null) 'altitud_m': altitudM,
        if (velocidadMps != null) 'velocidad_mps': velocidadMps,
        if (iniciaTramo) 'inicia_tramo': true,
      };
}