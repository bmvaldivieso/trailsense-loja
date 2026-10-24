import 'dart:math' as math;

/// Detecta pasos por los picos de aceleración. Solo se usa como estimación provisional:
/// el contador de pasos del sistema es la fuente exacta.
class DetectorPasos {
  double _suave = 9.81; // magnitud filtrada (quita vibración fina)
  double _base = 9.81;  // gravedad + orientación (cambia lento)
  bool _enPico = false;
  DateTime? _ultimoPaso;

  static const double _umbralSubida = 1.2;  // m/s² sobre la base para contar un paso
  static const double _umbralBajada = 0.4;  // histéresis: hay que bajar antes del siguiente
  static const Duration _minEntrePasos = Duration(milliseconds: 280);

  /// Devuelve true cuando detecta un paso nuevo.
  bool procesar(double x, double y, double z, DateTime ahora) {
    final double magnitud = math.sqrt(x * x + y * y + z * z);
    _suave += 0.3 * (magnitud - _suave);
    _base += 0.02 * (magnitud - _base);
    final double d = _suave - _base;

    if (!_enPico && d > _umbralSubida) {
      _enPico = true;
      if (_ultimoPaso == null || ahora.difference(_ultimoPaso!) >= _minEntrePasos) {
        _ultimoPaso = ahora;
        return true;
      }
    } else if (_enPico && d < _umbralBajada) {
      _enPico = false;
    }
    return false;
  }
}