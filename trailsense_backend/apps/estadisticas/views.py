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

from datetime import datetime
from django.db.models.functions import TruncMonth


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

MESES_ES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
            'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']


def _etiqueta_mes(anio, mes):
    return f"{MESES_ES[mes - 1].capitalize()} {anio}"


def _rango_mes(valor):
    """'2026-08' -> (inicio, fin) en hora local de Ecuador. None si el valor no es válido."""
    try:
        anio, mes = (int(x) for x in str(valor).split('-'))
        if not (2000 <= anio <= 2100 and 1 <= mes <= 12):
            return None
    except (ValueError, TypeError):
        return None
    inicio = timezone.make_aware(datetime(anio, mes, 1))
    fin = timezone.make_aware(datetime(anio + 1, 1, 1) if mes == 12 else datetime(anio, mes + 1, 1))
    return inicio, fin, _etiqueta_mes(anio, mes)    

def _calcular_resumen(usuario, periodo, mes=None):
    hasta = None
    etiqueta = None
    if periodo == 'mes_especifico':
        desde, hasta, etiqueta = _rango_mes(mes)      
    else:
        desde = _rango_fecha(periodo)

    sesiones = SesionCaminata.objects.filter(usuario=usuario, estado='finalizada')
    reportes = Reporte.objects.filter(usuario=usuario)
    if desde:
        sesiones = sesiones.filter(iniciado_en__gte=desde)
        reportes = reportes.filter(fecha_creacion__gte=desde)
    if hasta:                                          
        sesiones = sesiones.filter(iniciado_en__lt=hasta)
        reportes = reportes.filter(fecha_creacion__lt=hasta)

    agregados = sesiones.aggregate(distancia=Sum('distancia_km'), duracion=Sum('duracion_segundos'), pasos=Sum('pasos'))
    total_km = agregados['distancia'] or 0
    total_pasos = agregados['pasos'] or 0
    total_segundos = agregados['duracion'] or 0
    total_recorridos = sesiones.count()
    total_reportes = reportes.count()

    # Indicador de actividad calculado (heurística simple, documentada)
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
        "periodo_etiqueta": etiqueta,
    }

def _validar_periodo(request):
    """Devuelve (periodo, mes, error_response)."""
    periodo = request.query_params.get('periodo', 'mes')
    mes = request.query_params.get('mes')
    if periodo == 'mes_especifico' and not _rango_mes(mes):
        return periodo, mes, Response({'detail': 'Mes inválido. Usa el formato AAAA-MM.'}, status=400)
    return periodo, mes, None    

class MetricasPersonalesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        periodo, mes, error = _validar_periodo(request)
        if error:
            return error
        usuario = request.user

        resumen = _calcular_resumen(usuario, periodo, mes)
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
        periodo, mes, error = _validar_periodo(request)
        if error:
            return error
        resumen = _calcular_resumen(request.user, periodo, mes)
        return generar_pdf_metricas(resumen, periodo, sufijo=mes)


class MesesDisponiblesView(APIView):
    """Meses (hora de Ecuador) en los que el usuario tiene recorridos o reportes."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        tz = timezone.get_current_timezone()
        u = request.user
        de_sesiones = (SesionCaminata.objects.filter(usuario=u, estado='finalizada')
                       .annotate(m=TruncMonth('iniciado_en', tzinfo=tz))
                       .order_by().values_list('m', flat=True).distinct())
        de_reportes = (Reporte.objects.filter(usuario=u)
                       .annotate(m=TruncMonth('fecha_creacion', tzinfo=tz))
                       .order_by().values_list('m', flat=True).distinct())
        meses = sorted({(d.year, d.month) for d in [*de_sesiones, *de_reportes] if d}, reverse=True)
        return Response([{'valor': f'{a}-{m:02d}', 'etiqueta': _etiqueta_mes(a, m)} for a, m in meses])