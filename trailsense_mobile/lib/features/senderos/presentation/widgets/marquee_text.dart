import 'package:flutter/material.dart';

/// Texto en una línea que se desplaza de ida y vuelta solo si no cabe en el ancho disponible.
class MarqueeText extends StatefulWidget {
  final String texto;
  final TextStyle? style;
  const MarqueeText(this.texto, {super.key, this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final ScrollController _controller = ScrollController();
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ciclo());
  }

  @override
  void didUpdateWidget(covariant MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.texto != widget.texto && _controller.hasClients) _controller.jumpTo(0);
  }

  Future<void> _ciclo() async {
    while (mounted && _activo) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_controller.hasClients) continue;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) {                                   // cabe completo: no se mueve
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
      final duracion = Duration(milliseconds: (max / 30 * 1000).round());   // ~30 px/s
      await _controller.animateTo(max, duration: duracion, curve: Curves.linear);
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_controller.hasClients) return;
      await _controller.animateTo(0, duration: duracion, curve: Curves.linear);
    }
  }

  @override
  void dispose() {
    _activo = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.texto, style: widget.style, maxLines: 1, softWrap: false),
    );
  }
}