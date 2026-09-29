from io import BytesIO
from django.http import HttpResponse
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm

ETIQUETAS_PERIODO = {'dia': 'Hoy', 'semana': 'Última semana', 'mes': 'Último mes', 'todo': 'Histórico completo'}


def generar_pdf_metricas(resumen, periodo):
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    estilos = getSampleStyleSheet()

    elementos = [
        Paragraph(f"Métricas Personales — {resumen['nombre']}", estilos['Title']),
        Paragraph(f"Periodo: {ETIQUETAS_PERIODO.get(periodo, periodo)}", estilos['Normal']),
        Spacer(1, 0.6 * cm),
    ]

    datos = [
        ["Indicador", "Valor"],
        ["Distancia recorrida", f"{resumen['distancia_km']:.3f} km"],
        ["Pasos totales", str(resumen['pasos'])],
        ["Tiempo en movimiento", resumen['tiempo_texto']],
        ["Reportes creados", str(resumen['reportes'])],
        ["Recorridos realizados", str(resumen['recorridos'])],
        ["Miembro desde", resumen['fecha_registro']],
        ["Estado de actividad", resumen['estado']],
    ]

    tabla = Table(datos, colWidths=[8 * cm, 8 * cm])
    tabla.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3B82F6')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F8FAFC')]),
    ]))
    elementos.append(tabla)
    doc.build(elementos)

    buffer.seek(0)
    response = HttpResponse(buffer, content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="metricas_personales_{periodo}.pdf"'
    return response