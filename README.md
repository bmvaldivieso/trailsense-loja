## Configuración de HTTPS local (desarrollo)

Este proyecto usa `mkcert` para HTTPS en desarrollo local. Antes de compilar:

1. Instala mkcert: `mkcert -install`
2. Genera el certificado: `mkcert <tu-ip-local> localhost 127.0.0.1`
3. Copia el certificado generado a `trailsense_backend/certs/`
4. Copia el `rootCA.pem` (ubicado con `mkcert -CAROOT`) a `trailsense_mobile/assets/certs/rootCA.pem`
5. Instala el `rootCA.pem` como certificado de confianza en tu dispositivo Android de pruebas