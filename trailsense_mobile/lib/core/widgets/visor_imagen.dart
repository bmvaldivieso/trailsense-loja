import 'package:flutter/material.dart';

/// Abre una imagen a pantalla completa: pellizcar para hacer zoom, arrastrar para moverla,
/// tocar o usar la X para cerrar.
Future<void> abrirVisorImagen(BuildContext context, String url) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (BuildContext ctx, Animation<double> animation, Animation<double> _) =>
          FadeTransition(opacity: animation, child: _VisorImagen(url: url)),
    ),
  );
}

class _VisorImagen extends StatelessWidget {
  const _VisorImagen({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? progreso) =>
                        progreso == null ? child : const CircularProgressIndicator(color: Colors.white),
                    errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                        const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}