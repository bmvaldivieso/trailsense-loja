import 'package:flutter/material.dart';

class TipoNotificacion {
  final String valor;
  final String etiqueta;
  final IconData icono;
  final Color color;
  const TipoNotificacion(this.valor, this.etiqueta, this.icono, this.color);
}

const List<TipoNotificacion> tiposNotificacion = [
  TipoNotificacion('mantenimiento', 'Mantenimiento de la app', Icons.build_circle_outlined, Color(0xFF6366F1)),
  TipoNotificacion('sendero', 'Aviso de sendero', Icons.terrain, Color(0xFF16A34A)),
  TipoNotificacion('seguridad', 'Aviso de seguridad', Icons.warning_amber_rounded, Color(0xFFDC2626)),
  TipoNotificacion('comunicado', 'Comunicado', Icons.campaign_outlined, Color(0xFF0A9DFF)),
  TipoNotificacion('proximidad', 'Incidencia cercana', Icons.location_on, Color(0xFFF97316)),
  TipoNotificacion('acumulacion', 'Reportes acumulados', Icons.layers_outlined, Color(0xFFD97706)),
  TipoNotificacion('estado_sendero', 'Estado de sendero', Icons.alt_route, Color(0xFF14B8A6)),
];

TipoNotificacion tipoNotificacionPorValor(String valor) =>
    tiposNotificacion.firstWhere((t) => t.valor == valor, orElse: () => tiposNotificacion.first);