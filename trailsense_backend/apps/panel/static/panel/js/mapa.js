document.addEventListener('DOMContentLoaded', function () {
    const API = window.MAPA_API;
    const REFRESCO_MS = 60000;
    const CENTRO_LOJA = [-3.9973, -79.2005];

    const COLOR_ESTADO_SENDERO = { bueno: '#3b82f6', alerta: '#f59e0b', critico: '#dc2626' };
    const COLOR_ESTADO_REPORTE = { pendiente: '#f59e0b', aprobado: '#16a34a', rechazado: '#dc2626' };
    const COLOR_CATEGORIA = { deterioro: '#f97316', senalizacion: '#eab308', residuos: '#16a34a', obstaculo: '#ef4444', seguridad: '#b91c1c' };
    const COLOR_RECORRIDO = '#7c3aed';
    const COLOR_PIN_SENDERO = '#1e293b';

    const OPC_ESTADO_SENDERO = [['', 'Todos los estados'], ['bueno', 'Bueno'], ['alerta', 'Con alertas menores'], ['critico', 'Crítico']];
    const OPC_CATEGORIA = [['', 'Todas las categorías'], ['deterioro', 'Deterioro del camino'], ['senalizacion', 'Señalización deficiente'], ['residuos', 'Acumulación de residuos'], ['obstaculo', 'Obstáculo'], ['seguridad', 'Riesgo de seguridad']];
    const OPC_ESTADO_REPORTE = [['', 'Todos los estados'], ['pendiente', 'Pendiente'], ['aprobado', 'Aprobado'], ['rechazado', 'Rechazado']];
    const OPC_VINCULO = [['', 'Todos'], ['sendero', 'En un sendero'], ['libre', 'Recorrido libre']];
    const MENSAJE_VACIO = {
        senderos: 'Aún no hay senderos registrados.',
        incidencias: 'Aún no hay incidencias registradas.',
        recorridos: 'Aún no hay recorridos finalizados.',
    };

    const el = id => document.getElementById(id);
    const panel = el('panelMapa');
    const lista = el('listaMapa');
    const detalle = el('detalleMapa');
    const contFiltros = el('filtrosMapa');

    // ------------------------------------------------------------- utilidades
    const esc = t => String(t ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    const num = (v, d) => Number(v ?? 0).toFixed(d);
    const norm = t => String(t ?? '').toLowerCase();

    function duracion(seg) {
        const h = Math.floor(seg / 3600), m = Math.floor((seg % 3600) / 60), s = seg % 60;
        return h > 0 ? `${h}h ${m}min ${s}s` : `${m}min ${s}s`;
    }

    // ----------------------------------------------------------------- estado
    let datos = { senderos: [], incidencias: [], recorridos: [] };
    let firmaPrevia = '';
    let tipoActivo = 'senderos';
    let seleccion = null;            // { tipo, id }
    let colapsado = false;
    const capasVisibles = { senderos: true, incidencias: true, recorridos: false };
    const filtros = {
        senderos: { q: '', estado: '' },
        incidencias: { q: '', categoria: '', estado: '' },
        recorridos: { q: '', vinculo: '' },
    };
    let registro = { senderos: {}, incidencias: {}, recorridos: {} };

    // -------------------------------------------------------------------- mapa
    const mapa = L.map('mapaInteractivo', { attributionControl: false }).setView(CENTRO_LOJA, 13);
    L.control.attribution({ position: 'topright' }).addTo(mapa);   // visible: el panel inferior tapa la esquina habitual

    const key = window.CARTO_API_KEY || '';
    const urlTiles = key
        ? `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${key}`
        : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    L.tileLayer(urlTiles, { attribution: '&copy; OpenStreetMap contributors &copy; CARTO', maxZoom: 19, subdomains: 'abcd' }).addTo(mapa);

    const capas = { senderos: L.layerGroup(), incidencias: L.layerGroup(), recorridos: L.layerGroup() };
    Object.keys(capas).forEach(k => { if (capasVisibles[k]) capas[k].addTo(mapa); });

    const popup = L.popup({ maxWidth: 280, minWidth: 220, className: 'popup-mapa', autoPan: true });

    function altoPanelVisible() { return colapsado ? 44 : panel.offsetHeight; }

    function actualizarAltoPanel() {
        document.documentElement.style.setProperty('--alto-panel', altoPanelVisible() + 'px');
    }

    function opcionesAjuste(alto, maxZoom) {
        return { paddingTopLeft: [40, 40], paddingBottomRight: [40, alto + 30], maxZoom: maxZoom };
    }

    // Centra un punto en la zona VISIBLE del mapa (la que no tapa el panel)
    function centrarPunto(latlng, zoom) {
        const desplazamiento = altoPanelVisible() / 2;
        const punto = mapa.project(latlng, zoom).add([0, desplazamiento]);
        mapa.setView(mapa.unproject(punto, zoom), zoom, { animate: true });
    }

    function mostrarPopup(latlng, html) {
        popup.options.autoPanPaddingBottomRight = L.point(20, altoPanelVisible() + 20);
        popup.setLatLng(latlng).setContent(html).openOn(mapa);
    }

    // Abre el popup cuando termina el movimiento del mapa (con respaldo por si no hay movimiento)
    function moverYAbrir(mover, latlng, html) {
        let hecho = false;
        const abrir = () => { if (hecho) return; hecho = true; mostrarPopup(latlng, html); };
        mapa.once('moveend', abrir);
        mover();
        setTimeout(abrir, 700);
    }

    function ajustarVista() {
        const limites = L.latLngBounds([]);
        Object.entries(capas).forEach(([nombre, capa]) => {
            if (!capasVisibles[nombre]) return;
            capa.getLayers().forEach(l => limites.extend(l.getBounds ? l.getBounds() : l.getLatLng()));
        });
        if (limites.isValid()) mapa.fitBounds(limites, opcionesAjuste(altoPanelVisible(), 16));
        else mapa.setView(CENTRO_LOJA, 13);
    }

    // ---------------------------------------------------------------- estilos
    const estiloSendero = (s, activo) => ({ color: COLOR_ESTADO_SENDERO[s.estado] || '#64748b', weight: activo ? 8 : 5, opacity: activo ? 1 : 0.85 });
    const estiloRecorrido = activo => ({ color: COLOR_RECORRIDO, weight: activo ? 7 : 4, opacity: activo ? 1 : 0.65, dashArray: activo ? null : '6 6' });

    function iconoPin(color, tam, activo) {
        const t = activo ? Math.round(tam * 1.3) : tam;
        return L.divIcon({
            className: 'pin-mapa',
            html: `<i class="bi bi-geo-alt-fill" style="color:${color};font-size:${t}px"></i>`,
            iconSize: [t, t], iconAnchor: [t / 2, t],
        });
    }

    const esSel = (tipo, id) => !!seleccion && seleccion.tipo === tipo && seleccion.id === id;

    function aplicarEstilos() {
        Object.values(registro.senderos).forEach(r => {
            const activo = esSel('senderos', r.item.id);
            r.linea.setStyle(estiloSendero(r.item, activo));
            if (activo) r.linea.bringToFront();
        });
        Object.values(registro.recorridos).forEach(r => {
            const activo = esSel('recorridos', r.item.id);
            r.linea.setStyle(estiloRecorrido(activo));
            if (activo) r.linea.bringToFront();
        });
        Object.values(registro.incidencias).forEach(r => {
            const activo = esSel('incidencias', r.item.id);
            r.marker.setIcon(iconoPin(COLOR_CATEGORIA[r.item.categoria] || '#ef4444', 32, activo));
            r.marker.setZIndexOffset(activo ? 1000 : 0);
        });
    }

    // ----------------------------------------------------------------- filtros
    function filtrados(tipo) {
        const f = filtros[tipo], q = norm(f.q).trim();
        return datos[tipo].filter(x => {
            if (tipo === 'senderos') {
                if (f.estado && x.estado !== f.estado) return false;
                return !q || norm(`${x.nombre} ${x.canton} ${x.direccion} ${x.dificultad_display} ${x.estado_display}`).includes(q);
            }
            if (tipo === 'incidencias') {
                if (f.categoria && x.categoria !== f.categoria) return false;
                if (f.estado && x.estado !== f.estado) return false;
                return !q || norm(`${x.id} ${x.categoria_display} ${x.sendero_nombre} ${x.usuario_nombre} ${x.descripcion} ${x.fecha}`).includes(q);
            }
            if (f.vinculo === 'sendero' && !x.sendero_id) return false;
            if (f.vinculo === 'libre' && x.sendero_id) return false;
            return !q || norm(`${x.numero_usuario ?? x.id} ${x.usuario_nombre} ${x.sendero_nombre || 'libre'} ${x.fecha}`).includes(q);
        });
    }

    function selectHtml(clave, opciones, valor) {
        return `<select class="form-select form-select-sm" data-filtro="${clave}">` +
            opciones.map(([v, t]) => `<option value="${v}" ${v === valor ? 'selected' : ''}>${esc(t)}</option>`).join('') + '</select>';
    }

    function renderFiltros() {
        const f = filtros[tipoActivo];
        const marcador = { senderos: 'Buscar sendero...', incidencias: 'Buscar incidencia...', recorridos: 'Buscar por senderista, fecha o #...' }[tipoActivo];
        let extra = '';
        if (tipoActivo === 'senderos') extra = selectHtml('estado', OPC_ESTADO_SENDERO, f.estado);
        if (tipoActivo === 'incidencias') extra = selectHtml('categoria', OPC_CATEGORIA, f.categoria) + selectHtml('estado', OPC_ESTADO_REPORTE, f.estado);
        if (tipoActivo === 'recorridos') extra = selectHtml('vinculo', OPC_VINCULO, f.vinculo);
        contFiltros.innerHTML = `<input type="text" class="form-control form-control-sm" data-filtro="q" placeholder="${marcador}" value="${esc(f.q)}">${extra}`;
    }

    contFiltros.addEventListener('input', e => {
        if (e.target.dataset.filtro !== 'q') return;
        filtros[tipoActivo].q = e.target.value;
        refrescarVista();
    });
    contFiltros.addEventListener('change', e => {
        const k = e.target.dataset.filtro;
        if (!k || k === 'q') return;
        filtros[tipoActivo][k] = e.target.value;
        refrescarVista();
    });

    // -------------------------------------------------------------- lista
    function miniatura(url, icono) {
        return url ? `<img class="miniatura-item" src="${esc(url)}" alt="">` : `<div class="miniatura-vacia"><i class="bi ${icono}"></i></div>`;
    }

    function htmlItem(tipo, x) {
        const activo = esSel(tipo, x.id) ? ' activo' : '';
        if (tipo === 'senderos') {
            return `<div class="item-mapa${activo}" data-id="${x.id}">
                <div style="min-width:0">
                    <div class="item-titulo text-truncate">${esc(x.nombre)}</div>
                    <div class="item-sub marquee"><span class="marquee-texto">${esc([x.canton, x.direccion].filter(Boolean).join(' · '))}</span></div>
                    <div class="item-metricas">
                        <span>${num(x.longitud_km, 2)} km</span>
                        <span><span class="punto-estado" style="background:${COLOR_ESTADO_SENDERO[x.estado] || '#999'}"></span>${esc(x.estado_display)}</span>
                        <span>${x.recorridos} recorridos</span>
                    </div>
                </div>${miniatura(x.imagen, 'bi-signpost-split')}</div>`;
        }
        if (tipo === 'incidencias') {
            return `<div class="item-mapa${activo}" data-id="${x.id}">
                <div style="min-width:0">
                    <div class="item-titulo text-truncate">Incidencia ${x.id}</div>
                    <div class="item-sub text-truncate">${esc(x.sendero_nombre)}</div>
                    <div class="item-metricas">
                        <span>${esc(x.categoria_display)}</span>
                        <span><span class="punto-estado" style="background:${COLOR_ESTADO_REPORTE[x.estado] || '#999'}"></span>${esc(x.estado_display)}</span>
                    </div>
                </div>${miniatura(x.fotos[0], 'bi-megaphone')}</div>`;
        }
        return `<div class="item-mapa${activo}" data-id="${x.id}">
            <div style="min-width:0">
                <div class="item-titulo text-truncate">Recorrido #${x.numero_usuario ?? x.id}</div>
                <div class="item-sub text-truncate">${esc(x.usuario_nombre)}</div>
                <div class="item-metricas">
                    <span>${num(x.distancia_km, 3)} km</span><span>${duracion(x.duracion_segundos)}</span>
                    <span>${esc(x.sendero_nombre || 'Libre')}</span>
                </div>
            </div>${miniatura(null, 'bi-geo')}</div>`;
    }

    function renderLista() {
        const items = filtrados(tipoActivo);
        if (!items.length) {
            lista.innerHTML = `<div class="text-muted small p-3">${datos[tipoActivo].length ? 'Ningún resultado con los filtros actuales.' : MENSAJE_VACIO[tipoActivo]}</div>`;
            return;
        }
        lista.innerHTML = items.map(x => htmlItem(tipoActivo, x)).join('');
        window.activarMarquee(lista);
    }

    function marcarListaActiva(desplazar) {
        lista.querySelectorAll('.item-mapa').forEach(it => {
            const activo = esSel(tipoActivo, parseInt(it.dataset.id, 10));
            it.classList.toggle('activo', activo);
            if (activo && desplazar) it.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        });
    }

    lista.addEventListener('click', e => {
        const it = e.target.closest('.item-mapa');
        if (it) seleccionar(tipoActivo, parseInt(it.dataset.id, 10));
    });

    function renderTabs() {
        ['senderos', 'incidencias', 'recorridos'].forEach(t => {
            el('cont' + t.charAt(0).toUpperCase() + t.slice(1)).textContent = filtrados(t).length;
        });
    }

    // ------------------------------------------------------------------ detalle
    function metrica(icono, texto, color) {
        return `<div class="metrica"><i class="bi ${icono}" style="color:${color || '#3b82f6'}"></i><span>${esc(texto)}</span></div>`;
    }

    function renderDetalle(tipo, x) {
        if (tipo === 'senderos') {
            detalle.innerHTML = `
                <h5 class="detalle-titulo">${esc(x.nombre)}</h5>
                <div class="d-flex gap-3 align-items-start">
                    <div class="metricas-detalle flex-grow-1">
                        ${metrica('bi-circle-fill', x.estado_display, COLOR_ESTADO_SENDERO[x.estado])}
                        ${metrica('bi-graph-up-arrow', 'Dificultad ' + x.dificultad_display.toLowerCase())}
                        ${metrica('bi-rulers', num(x.longitud_km, 2) + ' km de recorrido')}
                        ${metrica('bi-geo-alt', x.canton || 'Sin cantón')}
                        ${metrica('bi-signpost-2', x.direccion || 'Calles no registradas')}
                        ${x.horario ? metrica('bi-clock', x.horario) : ''}
                        ${metrica('bi-signpost-split', x.recorridos + ' recorridos finalizados')}
                        ${metrica('bi-megaphone', x.reportes + ' incidencias reportadas')}
                    </div>
                    ${x.imagen ? `<img class="detalle-imagen foto-ampliable" src="${esc(x.imagen)}" alt="" title="Clic para ampliar">` : ''}
                </div>
                <div class="detalle-subtitulo">DESCRIPCIÓN:</div>
                <div class="detalle-texto">${esc(x.descripcion || 'Sin descripción registrada.')}</div>`;
            return;
        }
        if (tipo === 'incidencias') {
            detalle.innerHTML = `
                <h5 class="detalle-titulo">Incidencia ${x.id}</h5>
                <div class="metricas-detalle">
                    ${metrica('bi-tag-fill', x.categoria_display, COLOR_CATEGORIA[x.categoria])}
                    ${metrica('bi-circle-fill', x.estado_display, COLOR_ESTADO_REPORTE[x.estado])}
                    ${metrica('bi-signpost-split', x.sendero_nombre)}
                    ${metrica('bi-person', x.usuario_nombre)}
                    ${metrica('bi-calendar3', x.fecha)}
                    ${metrica('bi-pin-map', x.distancia_sendero_m !== null ? x.distancia_sendero_m + ' m del sendero' : 'Distancia no calculada')}
                    ${metrica('bi-geo-alt', num(x.lat, 5) + ', ' + num(x.lon, 5))}
                </div>
                <div class="detalle-subtitulo">DESCRIPCIÓN:</div>
                <div class="detalle-texto">${esc(x.descripcion)}</div>
                ${x.fotos.length ? `<div class="detalle-subtitulo">FOTOS:</div>
                    <div class="grilla-fotos-mapa">${x.fotos.map(f => `<img class="foto-ampliable" src="${esc(f)}" alt="" title="Clic para ampliar">`).join('')}</div>` : ''}`;
            return;
        }
        detalle.innerHTML = `
            <h5 class="detalle-titulo">Recorrido #${x.numero_usuario ?? x.id}</h5>
            <div class="metricas-detalle">
                ${metrica('bi-person', x.usuario_nombre)}
                ${metrica('bi-signpost-split', x.sendero_nombre || 'Recorrido libre')}
                ${metrica('bi-calendar3', x.fecha)}
                ${metrica('bi-rulers', num(x.distancia_km, 3) + ' km')}
                ${metrica('bi-stopwatch', duracion(x.duracion_segundos))}
                ${metrica('bi-speedometer2', num(x.velocidad_promedio_kmh, 1) + ' km/h')}
                ${metrica('bi-person-walking', x.pasos + ' pasos')}
            </div>`;
    }

    function renderDetalleActual() {
        const item = seleccion && seleccion.tipo === tipoActivo ? datos[tipoActivo].find(x => x.id === seleccion.id) : null;
        if (item) renderDetalle(tipoActivo, item);
        else detalle.innerHTML = '<div class="text-muted small">Selecciona un elemento de la lista o del mapa para ver su detalle.</div>';
    }

    // -------------------------------------------------------------------- popup
    function htmlPopup(tipo, x) {
        if (tipo === 'senderos') {
            return `<div class="popup-titulo">${esc(x.nombre)}</div>
                <div class="popup-linea"><span class="punto-estado" style="background:${COLOR_ESTADO_SENDERO[x.estado]}"></span>${esc(x.estado_display)} · ${esc(x.dificultad_display)}</div>
                <div class="popup-linea"><i class="bi bi-rulers"></i> ${num(x.longitud_km, 2)} km · ${esc(x.canton)}</div>
                ${x.direccion ? `<div class="popup-linea"><i class="bi bi-signpost-2"></i> ${esc(x.direccion)}</div>` : ''}
                ${x.horario ? `<div class="popup-linea"><i class="bi bi-clock"></i> ${esc(x.horario)}</div>` : ''}
                <div class="popup-linea">${x.recorridos} recorridos · ${x.reportes} incidencias</div>`;
        }
        if (tipo === 'incidencias') {
            const d = x.descripcion.length > 90 ? x.descripcion.slice(0, 90) + '…' : x.descripcion;
            return `<div class="popup-titulo">Incidencia ${x.id}: ${esc(x.categoria_display)}</div>
                <div class="popup-linea"><span class="punto-estado" style="background:${COLOR_ESTADO_REPORTE[x.estado]}"></span>${esc(x.estado_display)} · ${esc(x.sendero_nombre)}</div>
                <div class="popup-linea"><i class="bi bi-calendar3"></i> ${esc(x.fecha)}</div>
                <div class="popup-linea">${esc(d)}</div>`;
        }
        return `<div class="popup-titulo">Recorrido #${x.numero_usuario ?? x.id} · ${esc(x.usuario_nombre)}</div>
            <div class="popup-linea">${esc(x.sendero_nombre || 'Recorrido libre')} · ${esc(x.fecha)}</div>
            <div class="popup-linea"><i class="bi bi-rulers"></i> ${num(x.distancia_km, 3)} km · <i class="bi bi-stopwatch"></i> ${duracion(x.duracion_segundos)}</div>
            <div class="popup-linea"><i class="bi bi-speedometer2"></i> ${num(x.velocidad_promedio_kmh, 1)} km/h · ${x.pasos} pasos</div>`;
    }

    // ----------------------------------------------------------- dibujo del mapa
    function pintarMapa() {
        Object.values(capas).forEach(c => c.clearLayers());
        registro = { senderos: {}, incidencias: {}, recorridos: {} };

        filtrados('senderos').forEach(s => {
            if (s.coords.length < 2) return;
            const linea = L.polyline(s.coords, estiloSendero(s, false)).addTo(capas.senderos);
            const ini = L.marker(s.coords[0], { icon: iconoPin(COLOR_PIN_SENDERO, 26), keyboard: false }).addTo(capas.senderos);
            const fin = L.marker(s.coords[s.coords.length - 1], { icon: iconoPin(COLOR_PIN_SENDERO, 26), keyboard: false }).addTo(capas.senderos);
            [linea, ini, fin].forEach(l => l.on('click', e => seleccionar('senderos', s.id, { anclaje: e.latlng })));
            registro.senderos[s.id] = { linea, item: s };
        });

        filtrados('recorridos').forEach(r => {
            const linea = L.polyline(r.coords, estiloRecorrido(false)).addTo(capas.recorridos);
            linea.on('click', e => seleccionar('recorridos', r.id, { anclaje: e.latlng }));
            registro.recorridos[r.id] = { linea, item: r };
        });

        filtrados('incidencias').forEach(i => {
            const marker = L.marker([i.lat, i.lon], { icon: iconoPin(COLOR_CATEGORIA[i.categoria] || '#ef4444', 32), keyboard: false }).addTo(capas.incidencias);
            marker.on('click', e => seleccionar('incidencias', i.id, { anclaje: e.latlng }));
            registro.incidencias[i.id] = { marker, item: i };
        });

        aplicarEstilos();
    }

    function refrescarVista() {
        pintarMapa();
        renderLista();
        renderTabs();
    }

    // ---------------------------------------------------------------- selección
    function alternarCapa(tipo, visible) {
        capasVisibles[tipo] = visible;
        if (visible) capas[tipo].addTo(mapa); else mapa.removeLayer(capas[tipo]);
        const caja = document.querySelector(`[data-capa="${tipo}"]`);
        if (caja) caja.checked = visible;
    }

    function cambiarTab(tipo) {
        tipoActivo = tipo;
        if (!capasVisibles[tipo]) alternarCapa(tipo, true);
        document.querySelectorAll('.panel-tab').forEach(b => b.classList.toggle('activo', b.dataset.tab === tipo));
        renderFiltros();
        renderLista();
        renderDetalleActual();
    }

    function seleccionar(tipo, id, opciones = {}) {
        const item = datos[tipo].find(x => x.id === id);
        if (!item) return;

        if (tipo !== tipoActivo) cambiarTab(tipo);
        seleccion = { tipo, id };

        aplicarEstilos();
        marcarListaActiva(true);
        renderDetalle(tipo, item);

        const html = htmlPopup(tipo, item);
        if (opciones.anclaje) {          // clic directo sobre el mapa
            mostrarPopup(opciones.anclaje, html);
            return;
        }
        if (tipo === 'incidencias') {    // clic en la lista: centrar y abrir
            const punto = L.latLng(item.lat, item.lon);
            moverYAbrir(() => centrarPunto(punto, 17), punto, html);
        } else {
            const ancla = item.coords[Math.floor(item.coords.length / 2)];
            moverYAbrir(() => mapa.fitBounds(L.latLngBounds(item.coords), opcionesAjuste(altoPanelVisible(), 17)), ancla, html);
        }
    }

    document.querySelectorAll('.panel-tab').forEach(b => b.addEventListener('click', () => cambiarTab(b.dataset.tab)));
    document.querySelectorAll('[data-capa]').forEach(c => c.addEventListener('change', () => alternarCapa(c.dataset.capa, c.checked)));
    el('btnAjustarVista').addEventListener('click', ajustarVista);

    // --------------------------------------------------------------- panel
    el('btnTogglePanel').addEventListener('click', function () {
        colapsado = !colapsado;
        panel.classList.toggle('colapsado', colapsado);
        el('textoTogglePanel').textContent = colapsado ? 'Mostrar panel' : 'Ocultar panel';
        el('iconoTogglePanel').className = colapsado ? 'bi bi-chevron-up' : 'bi bi-chevron-down';
        actualizarAltoPanel();
    });

    window.addEventListener('resize', () => { mapa.invalidateSize(); actualizarAltoPanel(); });

    // ------------------------------------------------------------ visor de fotos
    const visor = el('visorFoto');
    const visorImg = el('visorFotoImg');
    document.body.appendChild(visor);   // fuera del contenedor del mapa, para que quede sobre todo

    let escala = 1, offX = 0, offY = 0;
    let arrastrando = false, iniX = 0, iniY = 0, ultimoArrastre = 0;

    function aplicarTransform() {
        visorImg.style.transform = `translate(${offX}px, ${offY}px) scale(${escala})`;
        visorImg.style.cursor = escala > 1 ? 'grab' : 'default';
    }

    function abrirVisor(src) {
        visorImg.src = src;
        escala = 1; offX = 0; offY = 0;
        aplicarTransform();
        visor.classList.remove('d-none');
    }

    function cerrarVisor() { visor.classList.add('d-none'); }

    detalle.addEventListener('click', e => {
        const img = e.target.closest('.foto-ampliable');
        if (img) abrirVisor(img.src);
    });

    // Clic fuera de la imagen = cerrar (salvo que se acabe de arrastrar)
    visor.addEventListener('click', e => {
        if (e.target !== visor || Date.now() - ultimoArrastre < 200) return;
        cerrarVisor();
    });

    document.addEventListener('keydown', e => {
        if (e.key === 'Escape' && !visor.classList.contains('d-none')) cerrarVisor();
    });

    visor.addEventListener('wheel', e => {
        e.preventDefault();
        escala = Math.min(Math.max(escala + (e.deltaY < 0 ? 0.2 : -0.2), 1), 5);
        if (escala === 1) { offX = 0; offY = 0; }
        aplicarTransform();
    }, { passive: false });

    visorImg.addEventListener('mousedown', e => {
        if (escala <= 1) return;
        arrastrando = true;
        iniX = e.clientX - offX;
        iniY = e.clientY - offY;
        visorImg.classList.add('arrastrando');
        visorImg.style.cursor = 'grabbing';
        e.preventDefault();
    });

    document.addEventListener('mousemove', e => {
        if (!arrastrando) return;
        offX = e.clientX - iniX;
        offY = e.clientY - iniY;
        aplicarTransform();
    });

    document.addEventListener('mouseup', () => {
        if (!arrastrando) return;
        arrastrando = false;
        ultimoArrastre = Date.now();
        visorImg.classList.remove('arrastrando');
        aplicarTransform();
    });

    // --------------------------------------------------------------- carga
    function inicial() {
        const p = new URLSearchParams(window.location.search);
        const objetivo = [['sendero', 'senderos'], ['incidencia', 'incidencias'], ['recorrido', 'recorridos']]
            .map(([param, tipo]) => [parseInt(p.get(param), 10), tipo])
            .find(([id]) => !isNaN(id));

        if (objetivo && datos[objetivo[1]].some(x => x.id === objetivo[0])) {
            seleccionar(objetivo[1], objetivo[0]);
            return;
        }
        ajustarVista();
    }

    async function cargar(primera) {
        try {
            const resp = await fetch(API, { credentials: 'same-origin' });
            if (!resp.ok) {
                if (primera) lista.innerHTML = '<div class="text-danger small p-3">No se pudieron cargar los datos del mapa.</div>';
                return;
            }
            const nuevo = await resp.json();
            el('textoActualizado').textContent = `Actualizado ${nuevo.generado}`;

            const firma = JSON.stringify([nuevo.senderos, nuevo.incidencias, nuevo.recorridos]);
            if (firma === firmaPrevia) return;      // sin cambios: no se redibuja nada
            firmaPrevia = firma;

            datos = { senderos: nuevo.senderos, incidencias: nuevo.incidencias, recorridos: nuevo.recorridos };
            refrescarVista();

            if (seleccion && !datos[seleccion.tipo].some(x => x.id === seleccion.id)) seleccion = null;
            renderDetalleActual();

            if (primera) inicial();
        } catch (e) {
            console.error('Error cargando el mapa:', e);
            if (primera) lista.innerHTML = '<div class="text-danger small p-3">Error de conexión.</div>';
        }
    }

    renderFiltros();
    renderDetalleActual();
    setTimeout(() => { mapa.invalidateSize(); actualizarAltoPanel(); }, 200);
    cargar(true);
    setInterval(() => cargar(false), REFRESCO_MS);
});