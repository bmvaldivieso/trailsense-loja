import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Panel inferior sobre un mapa. Arrastrar hacia abajo la barra gris (o el encabezado)
/// lo oculta; solo queda la barra. Arrastrar hacia arriba lo muestra otra vez.
/// El cuerpo NO es zona de arrastre, así no choca con el scroll de las listas.
class PanelDeslizable extends StatefulWidget {
  final Widget cuerpo;
  final Widget? encabezado;
  final Widget? botonFlotante; // viaja pegado al borde superior del panel
  final BoxConstraints? constraints;
  final BoxDecoration decoration;
  final double? horizontal;
  final double? espacioSuperior;
  final double? espacioBajoBarra;
  final double? espacioInferior;
  final double? alturaBarra;
  final CrossAxisAlignment alineacion;

  const PanelDeslizable({
    super.key,
    required this.cuerpo,
    this.encabezado,
    this.botonFlotante,
    this.constraints,
    this.decoration = const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    this.horizontal,
    this.espacioSuperior,
    this.espacioBajoBarra,
    this.espacioInferior,
    this.alturaBarra,
    this.alineacion = CrossAxisAlignment.start,
  });

  @override
  State<PanelDeslizable> createState() => _PanelDeslizableState();
}

class _PanelDeslizableState extends State<PanelDeslizable> {
  static const double _umbralVelocidad = 250;
  static const double _umbralDistancia = 20;

  bool _oculto = false;
  bool? _eraActual;
  double _arrastre = 0;

  // Al volver a esta pantalla (por ejemplo desde un detalle) el panel vuelve a estar visible.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final esActual = ModalRoute.of(context)?.isCurrent ?? true;
    if (_eraActual == false && esActual) _oculto = false;
    _eraActual = esActual;
  }

  void _cambiar(bool ocultar) {
    if (ocultar == _oculto) return;
    if (ocultar) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _oculto = ocultar);
  }

  void _alTerminarArrastre(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v > _umbralVelocidad || _arrastre > _umbralDistancia) {
      _cambiar(true);
    } else if (v < -_umbralVelocidad || _arrastre < -_umbralDistancia) {
      _cambiar(false);
    }
    _arrastre = 0;
  }

  Widget _colapsable(double f, Widget hijo) => ClipRect(
        child: Align(alignment: Alignment.topCenter, heightFactor: f, child: hijo),
      );

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final inset = MediaQuery.of(context).padding.bottom;
    final altoBarra = w.alturaBarra ?? 4.h;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (w.botonFlotante != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16.w, bottom: 12.h),
                child: w.botonFlotante,
              ),
            ),
          Container(
            constraints: w.constraints,
            decoration: w.decoration,
            padding: EdgeInsets.symmetric(horizontal: w.horizontal ?? 20.w),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _oculto ? 0 : 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, f, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: w.alineacion,
                children: [
                  // Zona de arrastre: barra + encabezado
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) => _arrastre = 0,
                    onVerticalDragUpdate: (d) => _arrastre += d.delta.dy,
                    onVerticalDragEnd: _alTerminarArrastre,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: w.espacioSuperior ?? 12.h),
                        Center(
                          child: Container(
                            width: 40.w,
                            height: altoBarra,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(altoBarra),
                            ),
                          ),
                        ),
                        _colapsable(
                          f,
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: w.alineacion,
                            children: [
                              SizedBox(height: w.espacioBajoBarra ?? 12.h),
                              if (w.encabezado != null) w.encabezado!,
                            ],
                          ),
                        ),
                        // Solo ocupa espacio cuando el panel está oculto (zona táctil de la barra)
                        SizedBox(height: (8.h + inset) * (1 - f)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: _colapsable(
                      f,
                      Padding(
                        padding: EdgeInsets.only(bottom: w.espacioInferior ?? 12.h),
                        child: w.cuerpo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}