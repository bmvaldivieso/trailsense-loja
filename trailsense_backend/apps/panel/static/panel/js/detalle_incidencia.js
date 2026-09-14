document.addEventListener('DOMContentLoaded', function () {
    const reporteId = window.REPORTE_ID;
    const URL_DETALLE = `/api/reportes/panel/${reporteId}/`;
    const URL_SENDEROS = '/api/reportes/panel/senderos-geojson/';

    let mapa = null;
    let estadoSeleccionado = 'pendiente';
    let escala = 1;
    let offsetX = 0, offsetY = 0;
    let arrastrando = false;
    let inicioX = 0, inicioY = 0;

    const elDescripcion = document.getElementById('detalleDescripcion');
    const elLat = document.getElementById('detalleLat');
    const elLon = document.getElementById('detalleLon');
    const elSendero = document.getElementById('detalleSendero');
    const elDistancia = document.getElementById('detalleDistanciaSendero');
    const elComentario = document.getElementById('detalleComentario');
    const grillaFotos = document.getElementById('grillaFotos');
    const btnGuardar = document.getElementById('btnGuardarEstado');
    const btnMapa = document.getElementById('btnVerMapa');
    const opcionesEstado = document.querySelectorAll('.opcion-estado');
    const lightboxOverlay = document.getElementById('lightboxOverlay');
    const lightboxImagen = document.getElementById('lightboxImagen');

    function actualizarTransform() {
        lightboxImagen.style.transform = `translate(${offsetX}px, ${offsetY}px) scale(${escala})`;
    }

    function marcarEstadoSeleccionado(estado) {
        estadoSeleccionado = estado;
        opcionesEstado.forEach(op => op.classList.toggle('seleccionado', op.dataset.estado === estado));
    }

    opcionesEstado.forEach(op => op.addEventListener('click', () => marcarEstadoSeleccionado(op.dataset.estado)));

    // Botón "Mapa" — sin funcionalidad por ahora
    if (btnMapa) {
        btnMapa.addEventListener('click', () => console.log('Botón Mapa: sin funcionalidad por ahora.'));
    }

    function cargarDetalle() {
        fetch(URL_DETALLE, { credentials: 'same-origin' })
            .then(resp => resp.json())
            .then(renderizarDetalle);
    }

    function renderizarDetalle(data) {
        elDescripcion.textContent = data.descripcion;
        elLat.value = data.lat;
        elLon.value = data.lon;
        elSendero.value = data.sendero_nombre || 'Sin sendero';
        elDistancia.value = data.distancia_sendero_m != null ? `${data.distancia_sendero_m.toFixed(1)} m` : 'No calculada';
        elComentario.value = data.comentario_admin || '';

        marcarEstadoSeleccionado(data.estado);

        grillaFotos.innerHTML = '';
        (data.fotos || []).forEach(foto => {
            const img = document.createElement('img');
            img.src = foto.imagen;
            img.alt = 'Foto del reporte';
            img.addEventListener('click', () => abrirLightbox(foto.imagen));
            grillaFotos.appendChild(img);
        });

        dibujarMapa(data);
    }

    function dibujarMapa(data) {
        if (mapa) { mapa.remove(); mapa = null; }

        const centro = [data.lat, data.lon];
        mapa = L.map('mapaDetalleIncidencia').setView(centro, 15);

        const cartoKey = window.CARTO_API_KEY || '';
        const tileUrl = cartoKey
            ? `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${cartoKey}`
            : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

        L.tileLayer(tileUrl, {
            attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
            maxZoom: 19, subdomains: 'abcd',
        }).addTo(mapa);

        L.marker(centro).addTo(mapa).bindPopup('Punto del reporte');

        // Dibuja los senderos como referencia de proximidad
        fetch(URL_SENDEROS, { credentials: 'same-origin' })
            .then(resp => resp.json())
            .then(geojson => {
                L.geoJSON(geojson, { style: { color: '#94a3b8', weight: 3, opacity: 0.7 } }).addTo(mapa);
            });

        setTimeout(() => mapa.invalidateSize(), 150);
    }

    btnGuardar.addEventListener('click', function () {
        const comentario = elComentario.value.trim();

        if (estadoSeleccionado === 'rechazado' && !comentario) {
            alert('El comentario es obligatorio para rechazar un reporte.');
            return;
        }

        btnGuardar.disabled = true;
        btnGuardar.textContent = 'Guardando...';

        fetch(URL_DETALLE, {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'Content-Type': 'application/json', 'X-CSRFToken': obtenerCsrfToken() },
            body: JSON.stringify({ estado: estadoSeleccionado, comentario_admin: comentario }),
        })
            .then(resp => resp.json().then(data => ({ ok: resp.ok, data })))
            .then(({ ok, data }) => {
                if (!ok) { alert(data.message || 'No se pudo guardar.'); return; }
                alert('Estado actualizado correctamente.');
            })
            .finally(() => {
                btnGuardar.disabled = false;
                btnGuardar.textContent = 'Guardar';
            });
    });

    function obtenerCsrfToken() {
        const match = document.cookie.match(/csrftoken=([^;]+)/);
        return match ? match[1] : '';
    }

    // Lightbox: zoom con rueda del mouse, cierre al clic fuera de la imagen
    function abrirLightbox(src) {
        lightboxImagen.src = src;
        escala = 1;
        offsetX = 0;
        offsetY = 0;
        actualizarTransform();
        lightboxOverlay.classList.remove('d-none');
    }

    lightboxOverlay.addEventListener('click', function (e) {
        if (e.target === lightboxOverlay) lightboxOverlay.classList.add('d-none');
    });

    lightboxImagen.addEventListener('wheel', function (e) {
        e.preventDefault();
        escala = Math.min(Math.max(escala + (e.deltaY < 0 ? 0.15 : -0.15), 1), 4);
        if (escala === 1) { offsetX = 0; offsetY = 0; }
        actualizarTransform();
    });

    // Arrastrar con clic izquierdo mientras hay zoom
    lightboxImagen.addEventListener('mousedown', function (e) {
        if (escala <= 1) return;
        arrastrando = true;
        inicioX = e.clientX - offsetX;
        inicioY = e.clientY - offsetY;
        lightboxImagen.style.cursor = 'grabbing';
        e.preventDefault();
    });

    document.addEventListener('mousemove', function (e) {
        if (!arrastrando) return;
        offsetX = e.clientX - inicioX;
        offsetY = e.clientY - inicioY;
        actualizarTransform();
    });

    document.addEventListener('mouseup', function () {
        if (arrastrando) {
            arrastrando = false;
            lightboxImagen.style.cursor = escala > 1 ? 'grab' : 'zoom-out';
        }
    });

    cargarDetalle();
});