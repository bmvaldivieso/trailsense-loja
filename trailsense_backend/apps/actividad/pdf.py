from io import BytesIO
from django.http import HttpResponse
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm

from django.utils import timezone

def generar_pdf_actividades(titulo, actividades, filename):
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=landscape(A4))
    estilos = getSampleStyleSheet()

    elementos = [Paragraph(titulo, estilos['Title']), Spacer(1, 0.5 * cm)]

    datos = [["Tipo de actividad", "Usuario", "Fecha y hora", "Detalle"]]
    for a in actividades:
        datos.append([a.get_tipo_display(), a.usuario.email, timezone.localtime(a.fecha).strftime('%d/%m/%Y %H:%M'), a.descripcion or '-'])

    tabla = Table(datos, colWidths=[6 * cm, 6 * cm, 4 * cm, 6 * cm])
    tabla.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3B82F6')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F8FAFC')]),
    ]))
    elementos.append(tabla)
    doc.build(elementos)

    buffer.seek(0)
    response = HttpResponse(buffer, content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    return response