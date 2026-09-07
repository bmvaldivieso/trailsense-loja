PUNTOS_POR_REPORTE_CREADO = 1

# Nota (Sprint 15 — validación/rechazo desde el panel):
# cuando se implemente esa funcionalidad, reutilizar esta misma función:
#   actualizar_reputacion(reporte.usuario, PUNTOS_POR_REPORTE_VALIDADO)
#   actualizar_reputacion(reporte.usuario, -PUNTOS_POR_REPORTE_RECHAZADO)
PUNTOS_POR_REPORTE_VALIDADO = 3
PUNTOS_POR_REPORTE_RECHAZADO = 2


def actualizar_reputacion(usuario, delta):
    nuevo_valor = (usuario.reputacion_score or 0) + delta
    usuario.reputacion_score = max(nuevo_valor, 0)   # nunca negativo
    usuario.save(update_fields=['reputacion_score'])