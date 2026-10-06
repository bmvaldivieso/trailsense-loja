class NotificacionModel {
  final int id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final String tipoDisplay;
  final String origen;
  final String? imagenUrl;
  final DateTime fecha;
  final bool leida;
  final int? senderoId;
  final String? senderoNombre;
  final String? senderoImagenUrl;
  final int? reporteId;

  NotificacionModel({
    required this.id, required this.titulo, required this.mensaje, required this.tipo,
    required this.tipoDisplay, required this.origen, this.imagenUrl, required this.fecha,
    required this.leida, this.senderoId, this.senderoNombre, this.senderoImagenUrl, this.reporteId,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> j) => NotificacionModel(
        id: j['id'],
        titulo: j['titulo'] ?? '',
        mensaje: j['mensaje'] ?? '',
        tipo: j['tipo'] ?? '',
        tipoDisplay: j['tipo_display'] ?? '',
        origen: j['origen'] ?? 'manual',
        imagenUrl: j['imagen'],
        fecha: DateTime.parse(j['fecha']).toLocal(),   // el servidor envía UTC; se muestra en la hora del dispositivo
        leida: j['leida'] ?? false,
        senderoId: j['sendero_id'],
        senderoNombre: j['sendero_nombre'],
        senderoImagenUrl: j['sendero_imagen'],
        reporteId: j['reporte_id'],
      );

  String get fechaTexto {
    String d(int v) => v.toString().padLeft(2, '0');
    return '${d(fecha.day)}/${d(fecha.month)}/${fecha.year}  ${d(fecha.hour)}:${d(fecha.minute)}';
  }
}

class ListadoNotificaciones {
  final List<NotificacionModel> items;
  final int noLeidas;
  ListadoNotificaciones({required this.items, required this.noLeidas});
}