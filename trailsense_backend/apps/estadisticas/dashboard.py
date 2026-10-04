from datetime import datetime, timedelta

from django.contrib.auth import get_user_model
from django.db.models import Avg, Count, Q, Sum
from django.db.models.functions import TruncDate, TruncMonth
from django.utils import timezone

from apps.actividad.models import RegistroActividad
from apps.reportes.models import FotoReporte, Reporte
from apps.senderos.models import Sendero
from apps.sesiones.models import PuntoGPS, SesionCaminata

Usuario = get_user_model()

MESES_ES = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
DIAS_ES = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']

# Heurística de "sin señal": un recorrido en curso cuyo último punto GPS recibido
# tiene más de UMBRAL minutos, y que inició hace menos de VIGENCIA horas.
UMBRAL_SIN_SENAL_MIN = 30 #Por defecto 30 minutos
VIGENCIA_ALERTA_HORAS = 24


# ------------------------------------------------------------------ utilidades
def _nombre(u):
    return f"{u.first_name} {u.last_name}".strip() or u.email


def _url(request, archivo):
    return request.build_absolute_uri(archivo.url) if archivo else None


def _pct(parte, total):
    return f"{round(parte / total * 100)}%" if total else "—"


def _ultimos_meses(n):
    hoy = timezone.localdate()
    anio, mes = hoy.year, hoy.month
    lista = []
    for _ in range(n):
        lista.append((anio, mes))
        mes -= 1
        if mes == 0:
            mes, anio = 12, anio - 1
    return list(reversed(lista))


def _serie_mensual(queryset, campo, n=12):
    meses = _ultimos_meses(n)
    inicio = timezone.make_aware(datetime(meses[0][0], meses[0][1], 1))
    filas = (queryset.filter(**{f'{campo}__gte': inicio})
             .annotate(m=TruncMonth(campo)).values('m').annotate(n=Count('id')))
    por_mes = {(f['m'].year, f['m'].month): f['n'] for f in filas}
    return {
        "etiquetas": [f"{MESES_ES[m - 1]} {str(a)[2:]}" for a, m in meses],
        "valores": [por_mes.get(k, 0) for k in meses],
    }


# ------------------------------------------------------------------------ KPIs
def _activos_7d():
    hace_7 = timezone.now() - timedelta(days=7)
    return (Usuario.objects.filter(rol='ciudadano')
            .filter(Q(sesiones_caminata__iniciado_en__gte=hace_7) | Q(reportes__fecha_creacion__gte=hace_7))
            .distinct().count())


def kpis_admin():
    return [
        {"etiqueta": "Senderistas", "valor": Usuario.objects.filter(rol='ciudadano').count(), "icono": "bi-people", "color": "primary"},
        {"etiqueta": "Senderos", "valor": Sendero.objects.count(), "icono": "bi-signpost-split", "color": "success"},
        {"etiqueta": "Reportes pendientes", "valor": Reporte.objects.filter(estado='pendiente').count(), "icono": "bi-hourglass-split", "color": "warning"},
        {"etiqueta": "Riesgos de seguridad por revisar", "valor": Reporte.objects.filter(categoria='seguridad', estado='pendiente').count(), "icono": "bi-shield-exclamation", "color": "danger"},
        {"etiqueta": "Senderistas activos (7 días)", "valor": _activos_7d(), "icono": "bi-activity", "color": "info"},
    ]


def kpis_superusuario():
    return [
        {"etiqueta": "Administradores", "valor": Usuario.objects.filter(rol='administrador').count(), "icono": "bi-person-gear", "color": "primary"},
        {"etiqueta": "Senderistas", "valor": Usuario.objects.filter(rol='ciudadano').count(), "icono": "bi-people", "color": "info"},
        {"etiqueta": "Senderos", "valor": Sendero.objects.count(), "icono": "bi-signpost-split", "color": "success"},
        {"etiqueta": "Reportes del sistema", "valor": Reporte.objects.count(), "icono": "bi-megaphone", "color": "danger"},
        {"etiqueta": "Senderistas activos (7 días)", "valor": _activos_7d(), "icono": "bi-activity", "color": "warning"},
    ]


# ------------------------------------------------- sensado y comunidad (tesis 3.2)
def sensado():
    fin = SesionCaminata.objects.filter(estado='finalizada').aggregate(n=Count('id'), km=Sum('distancia_km'))
    return {
        "oportunista": [
            {"etiqueta": "Recorridos capturados", "valor": fin['n']},
            {"etiqueta": "Distancia registrada", "valor": f"{(fin['km'] or 0):.1f} km"},
            {"etiqueta": "Puntos GPS recibidos", "valor": PuntoGPS.objects.count()},
        ],
        "participativo": [
            {"etiqueta": "Reportes creados", "valor": Reporte.objects.count()},
            {"etiqueta": "Fotografías recibidas", "valor": FotoReporte.objects.count()},
            {"etiqueta": "Reportes validados", "valor": Reporte.objects.filter(estado='aprobado').count()},
        ],
    }


def comunidad():
    agg = SesionCaminata.objects.filter(estado='finalizada').aggregate(
        seg=Sum('duracion_segundos'), pasos=Sum('pasos'),
        vel=Avg('velocidad_promedio_kmh', filter=Q(distancia_km__gt=0)),
    )
    total = Usuario.objects.filter(rol='ciudadano').count()
    # aggregate + Count(distinct) evita que el ordering por defecto del modelo rompa el conteo
    con_recorrido = SesionCaminata.objects.filter(estado='finalizada', usuario__rol='ciudadano') \
        .aggregate(n=Count('usuario', distinct=True))['n']
    con_reporte = Reporte.objects.filter(usuario__rol='ciudadano').aggregate(n=Count('usuario', distinct=True))['n']
    aprobados = Reporte.objects.filter(estado='aprobado').count()
    rechazados = Reporte.objects.filter(estado='rechazado').count()

    return [
        {"etiqueta": "Horas en movimiento", "valor": f"{(agg['seg'] or 0) / 3600:.1f} h"},
        {"etiqueta": "Velocidad promedio", "valor": f"{(agg['vel'] or 0):.1f} km/h"},
        {"etiqueta": "Pasos totales", "valor": f"{(agg['pasos'] or 0):,}".replace(',', '.')},
        {"etiqueta": "Senderistas con recorridos", "valor": _pct(con_recorrido, total)},
        {"etiqueta": "Senderistas con reportes", "valor": _pct(con_reporte, total)},
        {"etiqueta": "Tasa de aprobación de reportes", "valor": _pct(aprobados, aprobados + rechazados)},
    ]


# ------------------------------------------------------------------- gráficos
def actividad_semanal():
    hoy = timezone.localdate()
    dias = [hoy - timedelta(days=i) for i in range(6, -1, -1)]

    def contar(qs, campo):
        filas = (qs.filter(**{f'{campo}__date__gte': dias[0]})
                 .annotate(d=TruncDate(campo)).values('d').annotate(n=Count('id')))
        return {f['d']: f['n'] for f in filas}

    rep = contar(Reporte.objects.all(), 'fecha_creacion')
    rec = contar(SesionCaminata.objects.filter(estado='finalizada'), 'iniciado_en')
    return {
        "etiquetas": [f"{DIAS_ES[d.weekday()]} {d.day}" for d in dias],
        "reportes": [rep.get(d, 0) for d in dias],
        "recorridos": [rec.get(d, 0) for d in dias],
    }


def incidencias_por_categoria():
    filas = Reporte.objects.exclude(estado='rechazado').values('categoria').annotate(n=Count('id'))
    por = {f['categoria']: f['n'] for f in filas}
    return [{"clave": k, "etiqueta": v, "valor": por.get(k, 0)} for k, v in Reporte.CATEGORIA_CHOICES]


def salud_senderos():
    por = {f['estado']: f['n'] for f in Sendero.objects.values('estado').annotate(n=Count('id'))}
    return [{"clave": k, "etiqueta": v, "valor": por.get(k, 0)} for k, v in Sendero.ESTADO_CHOICES]


def puntos_calor():
    ubicaciones = Reporte.objects.exclude(estado='rechazado').values_list('ubicacion', flat=True)
    return [[p.y, p.x, 1] for p in ubicaciones]


# ------------------------------------------------------------- listas y tarjetas
def senderos_destacados(request, limite=2):
    qs = Sendero.objects.annotate(
        n=Count('sesiones', filter=Q(sesiones__estado='finalizada'))
    ).order_by('-n', '-creado_en')[:limite]
    return [{
        "id": s.id, "nombre": s.nombre, "longitud_km": s.longitud_km,
        "estado": s.estado, "estado_display": s.get_estado_display(),
        "imagen": _url(request, s.imagen_portada), "recorridos": s.n,
    } for s in qs]


def incidencias_recientes(request, limite=2):
    qs = Reporte.objects.select_related('sendero').prefetch_related('fotos').order_by('-fecha_creacion')[:limite]
    resultado = []
    for r in qs:
        fotos = list(r.fotos.all())
        resultado.append({
            "id": r.id, "sendero_nombre": r.sendero.nombre, "categoria": r.get_categoria_display(),
            "estado": r.estado, "descripcion": (r.descripcion[:70] + '…') if len(r.descripcion) > 70 else r.descripcion,
            "foto": _url(request, fotos[0].imagen) if fotos else None,
        })
    return resultado


def actividad_reciente(limite=5, **filtros):
    qs = RegistroActividad.objects.filter(**filtros).select_related('usuario')[:limite]
    return [{
        "tipo": a.tipo, "tipo_display": a.get_tipo_display(), "usuario": _nombre(a.usuario),
        "fecha": timezone.localtime(a.fecha).strftime('%d/%m/%Y %H:%M'), "descripcion": a.descripcion,
    } for a in qs]


def carrusel_senderistas(request):
    qs = Usuario.objects.filter(rol='ciudadano')
    top = qs.order_by('-reputacion_score', '-total_reportes')[:10]
    return {"total": qs.count(), "items": [
        {"nombre": _nombre(u), "foto": _url(request, u.foto_perfil), "subtitulo": f"Reputación {u.reputacion_score:g}"}
        for u in top]}


def carrusel_admins(request):
    qs = Usuario.objects.filter(rol='administrador')
    return {"total": qs.count(), "items": [
        {"nombre": _nombre(u), "foto": _url(request, u.foto_perfil), "subtitulo": "Administrador"}
        for u in qs.order_by('-date_joined')[:10]]}


# --------------------------------------------- última posición conocida (sin señal)
def sin_actividad():
    ahora = timezone.now()
    limite_inactividad = ahora - timedelta(minutes=UMBRAL_SIN_SENAL_MIN)
    limite_vigencia = ahora - timedelta(hours=VIGENCIA_ALERTA_HORAS)

    sesiones = (SesionCaminata.objects
                .filter(estado='en_curso', iniciado_en__gte=limite_vigencia)
                .select_related('usuario', 'sendero'))
    alertas = []
    for s in sesiones:
        ultimo = s.puntos.order_by('-capturado_en').first()
        if ultimo is None or ultimo.capturado_en > limite_inactividad:
            continue
        alertas.append({
            "sesion_id": s.id,
            "usuario": _nombre(s.usuario),
            "sendero": s.sendero.nombre if s.sendero else None,
            "lat": ultimo.ubicacion.y, "lon": ultimo.ubicacion.x,
            "ultima_hora": timezone.localtime(ultimo.capturado_en).strftime('%d/%m/%Y %H:%M'),
            "hace_minutos": int((ahora - ultimo.capturado_en).total_seconds() // 60),
            "precision_m": round(ultimo.precision_m, 1) if ultimo.precision_m is not None else None,
        })
    alertas.sort(key=lambda a: a['hace_minutos'])   # primero la pérdida de contacto más reciente
    return alertas


# --------------------------------------------------------------------- ensamblado
def construir_dashboard(request):
    es_super = request.user.rol == 'superusuario'

    data = {
        "rol": request.user.rol,
        "kpis": kpis_superusuario() if es_super else kpis_admin(),
        "sensado": sensado(),
        "comunidad": comunidad(),
        "actividad_semanal": actividad_semanal(),
        "incidencias_categoria": incidencias_por_categoria(),
        "balance_mensual": _serie_mensual(Reporte.objects.all(), 'fecha_creacion'),
        "registros_mensuales": _serie_mensual(Usuario.objects.filter(rol='ciudadano'), 'date_joined'),
        "recorridos_mensuales": _serie_mensual(SesionCaminata.objects.filter(estado='finalizada'), 'iniciado_en'),
        "salud_senderos": salud_senderos(),
        "calor": puntos_calor(),
        "sin_actividad": sin_actividad(),
        "umbral_sin_senal_min": UMBRAL_SIN_SENAL_MIN,
    }

    if es_super:
        data["incidencias_recientes"] = incidencias_recientes(request)
        data["actividad_reciente"] = actividad_reciente(usuario__rol__in=('administrador', 'superusuario'))
        data["actividad_reciente_senderistas"] = actividad_reciente(usuario__rol='ciudadano')
        data["carrusel_principal"] = carrusel_admins(request)
        data["carrusel_senderistas"] = carrusel_senderistas(request)
    else:
        data["senderos_destacados"] = senderos_destacados(request)
        data["actividad_reciente"] = actividad_reciente(usuario__rol='ciudadano')
        data["carrusel_principal"] = carrusel_senderistas(request)

    return data