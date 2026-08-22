from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.core.mail import EmailMultiAlternatives
from django.conf import settings


def enviar_correo_verificacion(usuario, codigo, asunto="Código de verificación - TrailSense Loja"):
    """
    Envía el correo de verificación en HTML, con una versión
    en texto plano como respaldo para clientes de correo antiguos.
    """
    contexto = {
        "nombre": usuario.first_name or "Senderista",
        "codigo": codigo,
        "minutos_expiracion": 15,
    }

    html_content = render_to_string(
        "usuarios/emails/codigo_verificacion.html",
        contexto,
    )
    text_content = strip_tags(html_content)

    email = EmailMultiAlternatives(
        subject=asunto,
        body=text_content,
        from_email=settings.DEFAULT_FROM_EMAIL,
        to=[usuario.email],
    )
    email.attach_alternative(html_content, "text/html")
    email.send(fail_silently=False)


def enviar_correo_recuperacion(usuario, codigo):
    """
    Envía el correo de recuperación de contraseña en HTML,
    con una versión en texto plano como respaldo.
    """
    contexto = {
        "nombre": usuario.first_name or "Senderista",
        "codigo": codigo,
        "minutos_expiracion": 15,
    }

    html_content = render_to_string(
        "usuarios/emails/codigo_recuperacion.html",
        contexto,
    )
    text_content = strip_tags(html_content)

    email = EmailMultiAlternatives(
        subject="Recuperación de contraseña - TrailSense Loja",
        body=text_content,
        from_email=settings.DEFAULT_FROM_EMAIL,
        to=[usuario.email],
    )
    email.attach_alternative(html_content, "text/html")
    email.send(fail_silently=False)