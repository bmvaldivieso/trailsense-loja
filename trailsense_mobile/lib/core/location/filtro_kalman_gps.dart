import 'dart:math' as math;

/// Filtro de Kalman 2D para posiciones GPS. Combina cada lectura con la estimación previa
/// ponderando por su precisión: elimina el temblor del GPS sin retrasar el movimiento real.
class FiltroKalmanGps {
  FiltroKalmanGps({this.ruidoProcesoMps = 3.0});

  /// Cuánto puede cambiar la posición real por segundo (caminata/trote ≈ 3 m/s).
  final double ruidoProcesoMps;

  double _lat = 0;
  double _lon = 0;
  double _varianza = -1; // m²; negativo = sin inicializar
  int _tsMs = 0;

  void reiniciar() => _varianza = -1;

  ({double lat, double lon}) procesar(double lat, double lon, double precisionM, int tsMs) {
    final double precision = math.max(precisionM, 1.0);
    if (_varianza < 0) {
      _lat = lat;
      _lon = lon;
      _varianza = precision * precision;
      _tsMs = tsMs;
      return (lat: _lat, lon: _lon);
    }
    final int dt = tsMs - _tsMs;
    if (dt > 0) {
      _varianza += dt * ruidoProcesoMps * ruidoProcesoMps / 1000;
      _tsMs = tsMs;
    }
    final double k = _varianza / (_varianza + precision * precision);
    _lat += k * (lat - _lat);
    _lon += k * (lon - _lon);
    _varianza = (1 - k) * _varianza;
    return (lat: _lat, lon: _lon);
  }
}