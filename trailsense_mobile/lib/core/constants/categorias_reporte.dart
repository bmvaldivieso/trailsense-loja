import 'package:flutter/material.dart';

class CategoriaReporte {
  final String valor;
  final String etiqueta;
  final IconData icono;
  final Color color;

  const CategoriaReporte({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });
}

const List<CategoriaReporte> categoriasReporte = [
  CategoriaReporte(valor: 'deterioro', etiqueta: 'Deterioro del camino', icono: Icons.terrain, color: Color(0xFFFF8A00)),
  CategoriaReporte(valor: 'senalizacion', etiqueta: 'Señalización deficiente', icono: Icons.signpost, color: Color(0xFFF59E0B)),
  CategoriaReporte(valor: 'residuos', etiqueta: 'Acumulación de residuos', icono: Icons.delete_outline, color: Color(0xFF16A34A)),
  CategoriaReporte(valor: 'obstaculo', etiqueta: 'Obstáculo', icono: Icons.block, color: Color(0xFFEF4444)),
  CategoriaReporte(valor: 'seguridad', etiqueta: 'Riesgo de seguridad', icono: Icons.warning_amber, color: Color(0xFFDC2626)),
];

CategoriaReporte categoriaPorValor(String valor) {
  return categoriasReporte.firstWhere(
    (c) => c.valor == valor,
    orElse: () => categoriasReporte.first,
  );
}