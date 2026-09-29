from calendar import month_abbr
from datetime import timedelta

from django.utils import timezone
from django.db.models import Sum, Avg

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from apps.sesiones.models import SesionCaminata
from apps.reportes.models import Reporte, FotoReporte
from .pdf import generar_pdf_metricas


def _rango_fecha(periodo):
    ahora_local = timezone.localtime(timezone.now())   # Convierte a hora de Ecuador primero

    if periodo == 'dia':
        # Inicio del día de HOY en hora local (00:00 Ecuador), no "últimas 24h"
        return ahora_local.replace(hour=0, minute=0, second=0, microsecond=0)

    if periodo == 'semana':
        inicio_dia = ahora_local.replace(hour=0, minute=0, second=0, microsecond=0)
        return inicio_dia - timedelta(days=ahora_local.weekday())   # lunes de esta semana

    if periodo == 'mes':
        return ahora_local.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    return None   # 'todo'


def _calcular_resumen(usuario, periodo):
    desde = _rango_fecha(periodo)

    sesiones = SesionCaminata.objects.filter(usuario=usuario, estado='finalizada')
    reportes = Reporte.objects.filter(usuario=usuario)
    if desde:
        sesiones = sesiones.filter(iniciado_en__gte=desde)
        reportes = reportes.filter(fecha_creacion__gte=desde)

    agregados = sesiones.aggregate(distancia=Sum('distancia_km'), duracion=Sum('duracion_segundos'), pasos=Sum('pasos'))
    total_km = agregados['distancia'] or 0
    total_pasos = agregados['pasos'] or 0
    total_segundos = agregados['duracion'] or 0
    total_recorridos = sesiones.count()
    total_reportes = reportes.count()

    # NUEVO: indicador de actividad calculado (heurística simple, documentada)
    if total_recorridos == 0:
        estado = 'Inactivo'
    elif total_recorridos <= 3:
        estado = 'Regular'
    else:
        estado = 'Excelente'

    horas, minutos = divmod(int(total_segundos) // 60, 60)
    segundos = int(total_segundos) % 60

    return {
        "nombre": f"{usuario.first_name} {usuario.last_name}".strip() or usuario.email,
        "distancia_km": round(total_km, 3),
        "pasos": total_pasos,
        "tiempo_texto": f"{horas}h {minutos}min {segundos}s 000ms",
        "reportes": total_reportes,
        "recorridos": total_recorridos,
        "fecha_registro": usuario.date_joined.strftime('%d-%m-%Y'),
        "estado": estado,
    }


class MetricasPersonalesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        periodo = request.query_params.get('periodo', 'mes')
        usuario = request.user

        resumen = _calcular_resumen(usuario, periodo)
        resumen['foto'] = request.build_absolute_uri(usuario.foto_perfil.url) if usuario.foto_perfil else None

        # Gráfico "Estadísticas Mensuales": últimos 6 meses, vitalicio (no filtra por periodo)
        ahora = timezone.localtime(timezone.now())
        mensuales = []
        for i in range(5, -1, -1):
            mes_ref = ahora - timedelta(days=30 * i)
            inicio_mes = mes_ref.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            if inicio_mes.month == 12:
                fin_mes = inicio_mes.replace(year=inicio_mes.year + 1, month=1)
            else:
                fin_mes = inicio_mes.replace(month=inicio_mes.month + 1)

            km_mes = SesionCaminata.objects.filter(
                usuario=usuario, estado='finalizada', iniciado_en__gte=inicio_mes, iniciado_en__lt=fin_mes
            ).aggregate(s=Sum('distancia_km'))['s'] or 0

            mensuales.append({"mes": month_abbr[mes_ref.month].capitalize(), "km": round(km_mes, 3)})

        # "Estadísticas Vitalicias": todas las sesiones finalizadas, sin filtro de periodo
        vitalicias = SesionCaminata.objects.filter(usuario=usuario, estado='finalizada').aggregate(
            tiempo_total=Sum('duracion_segundos'), velocidad_prom=Avg('velocidad_promedio_kmh'),
        )
        tiempo_total_h = round((vitalicias['tiempo_total'] or 0) / 3600, 2)

        # "Estadística de Aplicación": composición real de actividad, vitalicia
        total_recorridos_vida = SesionCaminata.objects.filter(usuario=usuario, estado='finalizada').count()
        total_reportes_vida = Reporte.objects.filter(usuario=usuario).count()
        total_fotos_vida = FotoReporte.objects.filter(reporte__usuario=usuario).count()
        total_actividad = total_recorridos_vida + total_reportes_vida + total_fotos_vida

        def pct(valor):
            return round((valor / total_actividad) * 100) if total_actividad > 0 else 0

        return Response({
            "resumen": resumen,
            "mensuales": mensuales,
            "vitalicias": {
                "tiempo_movimiento_h": tiempo_total_h,
                "distancia_km": usuario.kilometros_recorridos,
                "velocidad_promedio_kmh": round(vitalicias['velocidad_prom'] or 0, 1),
            },
            "composicion": {
                "recorridos": pct(total_recorridos_vida),
                "reportes": pct(total_reportes_vida),
                "fotos": pct(total_fotos_vida),
            },
        })


class MetricasPersonalesPDFView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        periodo = request.query_params.get('periodo', 'mes')
        resumen = _calcular_resumen(request.user, periodo)
        return generar_pdf_metricas(resumen, periodo)