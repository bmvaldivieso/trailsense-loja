from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.authentication import SessionAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.actividad.utils import registrar_actividad
from apps.senderos.models import Sendero
from core.permissions.roles import EsAdminOSuperusuario
from .models import Notificacion

Usuario = get_user_model()


def _nombre(u):
    return f"{u.first_name} {u.last_name}".strip() or u.email


def _entero(valor):
    try:
        return int(valor)
    except (TypeError, ValueError):
        return None


def _error(codigo, mensaje):
    return Response({"error": codigo, "message": mensaje}, status=400)


def _dict_panel(n, request):
    return {
        "id": n.id, "titulo": n.titulo, "mensaje": n.mensaje,
        "tipo": n.tipo, "tipo_display": n.get_tipo_display(),
        "imagen": request.build_absolute_uri(n.imagen.url) if n.imagen else None,
        "destino": 'todos' if n.destinatario_id is None else 'usuario',
        "destinatario_id": n.destinatario_id,
        "destinatario_nombre": _nombre(n.destinatario) if n.destinatario else 'Todos los senderistas',
        "sendero_id": n.sendero_id, "sendero_nombre": n.sendero.nombre if n.sendero else None,
        "fecha": timezone.localtime(n.fecha_creacion).strftime('%d/%m/%Y %H:%M'),
    }


def _guardar(request, n):
    d = request.data
    titulo = (d.get('titulo') or '').strip()
    mensaje = (d.get('mensaje') or '').strip()
    tipo = d.get('tipo')
    destino = d.get('destino', 'todos')

    if not titulo or len(titulo) > 120:
        return _error('titulo_invalido', 'El título es obligatorio (máximo 120 caracteres).')
    if not mensaje or len(mensaje) > 1000:
        return _error('mensaje_invalido', 'El mensaje es obligatorio (máximo 1000 caracteres).')
    if tipo not in Notificacion.TIPOS_MANUALES:
        return _error('tipo_invalido', 'Selecciona un tipo de notificación válido.')

    destinatario = None
    if destino == 'usuario':
        destinatario = Usuario.objects.filter(pk=_entero(d.get('destinatario')) or 0, rol='ciudadano').first()
        if destinatario is None:
            return _error('destinatario_invalido', 'Selecciona el senderista que recibirá la notificación.')

    sendero = None
    sendero_id = _entero(d.get('sendero'))
    if sendero_id:
        sendero = Sendero.objects.filter(pk=sendero_id).first()
        if sendero is None:
            return _error('sendero_invalido', 'El sendero seleccionado no existe.')

    imagen = request.FILES.get('imagen')
    if imagen and not (imagen.content_type or '').startswith('image/'):
        return _error('imagen_invalida', 'El archivo adjunto debe ser una imagen.')

    creando = n is None
    if creando:
        n = Notificacion(origen='manual', creado_por=request.user)

    n.titulo, n.mensaje, n.tipo = titulo, mensaje, tipo
    n.destinatario, n.sendero = destinatario, sendero
    if imagen:
        n.imagen = imagen
    n.save()

    if creando:
        registrar_actividad(request.user, 'notificacion_creada', f"Notificación: {titulo}")

    return Response(_dict_panel(n, request), status=201 if creando else 200)


class NotificacionesPanelView(APIView):
    """GET lista de manuales · POST crear."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        qs = Notificacion.objects.filter(origen='manual').select_related('destinatario', 'sendero')
        return Response([_dict_panel(n, request) for n in qs])

    def post(self, request):
        return _guardar(request, None)


class NotificacionPanelDetalleView(APIView):
    """GET detalle · POST editar · DELETE eliminar."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def _obtener(self, pk):
        return get_object_or_404(Notificacion.objects.select_related('destinatario', 'sendero'), pk=pk, origen='manual')

    def get(self, request, pk):
        return Response(_dict_panel(self._obtener(pk), request))

    def post(self, request, pk):
        return _guardar(request, self._obtener(pk))

    def delete(self, request, pk):
        self._obtener(pk).delete()
        return Response(status=204)


class NotificacionesOpcionesView(APIView):
    """GET datos para llenar el formulario (tipos, senderos, senderistas)."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated, EsAdminOSuperusuario]

    def get(self, request):
        return Response({
            "tipos": [{"valor": v, "etiqueta": e} for v, e in Notificacion.TIPO_CHOICES if v in Notificacion.TIPOS_MANUALES],
            "senderos": list(Sendero.objects.order_by('nombre').values('id', 'nombre')),
            "senderistas": [
                {"id": u.id, "nombre": _nombre(u), "email": u.email}
                for u in Usuario.objects.filter(rol='ciudadano').order_by('first_name', 'email')
            ],
        })