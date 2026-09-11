import mimetypes
from pathlib import Path

import boto3
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Sube los archivos existentes en la carpeta media/ local al bucket de S3, conservando la misma ruta relativa (no modifica la base de datos)."

    def handle(self, *args, **options):
        if not settings.AWS_ACCESS_KEY_ID or not settings.AWS_STORAGE_BUCKET_NAME:
            raise CommandError("Faltan credenciales AWS en tu .env (AWS_ACCESS_KEY_ID / AWS_STORAGE_BUCKET_NAME).")

        local_media_root = Path(settings.BASE_DIR) / "media"

        if not local_media_root.exists():
            self.stdout.write(self.style.WARNING(f"No existe la carpeta {local_media_root}, nada que migrar."))
            return

        cliente = boto3.client(
            "s3",
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_S3_REGION_NAME,
        )

        total = 0
        for ruta_absoluta in local_media_root.rglob("*"):
            if ruta_absoluta.is_file():
                clave_relativa = ruta_absoluta.relative_to(local_media_root).as_posix()
                content_type, _ = mimetypes.guess_type(str(ruta_absoluta))

                self.stdout.write(f"Subiendo: {clave_relativa}")
                cliente.upload_file(
                    str(ruta_absoluta),
                    settings.AWS_STORAGE_BUCKET_NAME,
                    clave_relativa,
                    ExtraArgs={"ContentType": content_type or "application/octet-stream"},
                )
                total += 1

        self.stdout.write(self.style.SUCCESS(f"Migración completa: {total} archivo(s) subidos a S3."))