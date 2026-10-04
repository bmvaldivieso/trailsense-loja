document.addEventListener('DOMContentLoaded', function () {
    const API = window.DASHBOARD_API;
    const INTERVALO_REFRESCO_MS = 60000;

    const IMG_AVATAR = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
    const IMG_SENDERO = 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=400&q=80';
    const COLOR_ESTADO_SENDERO = { bueno: '#3b82f6', alerta: '#f59e0b', critico: '#dc2626' };
    const COLORES_CATEGORIA = ['#f97316', '#eab308', '#16a34a', '#ef4444', '#6366f1'];
    const ICONOS_TIPO = {
        reporte_creado: 'bi-megaphone text-danger',
        perfil_actualizado: 'bi-person-gear text-primary',
        recorrido_finalizado: 'bi-signpost-split text-success',
        descarga_pdf_estadisticas: 'bi-file-earmark-pdf text-warning',
        sendero_creado: 'bi-plus-circle text-success',
        sendero_actualizado: 'bi-pencil-square text-primary',
        sendero_eliminado: 'bi-trash text-danger',
        descarga_pdf_historial: 'bi-file-earmark-pdf text-warning',
        notificacion_creada: 'bi-bell text-info',
    };

    const graficos = {};
    let mapa = null, capaCalor = null, capaSinActividad = null;
    let ultimaListaSinActividad = [], marcadores = [];

    const el = id => document.getElementById(id);

    // La guía vive dentro del contenido con scroll: se mueve al <body> para que el modal se muestre bien
    const modalGuia = el('modalGuiaDashboard');
    if (modalGuia) document.body.appendChild(modalGuia);

    // Si el título de una tarjeta no cabe, se activa la animación que lo desplaza
    function activarMarquee() {
        document.querySelectorAll('.marquee-texto').forEach(t => {
            t.classList.remove('marquee-activo');
            t.style.removeProperty('--desp');
            const extra = t.offsetWidth - t.parentElement.clientWidth;
            if (extra > 2) {
                t.style.setProperty('--desp', `-${extra + 6}px`);
                t.style.animationDuration = `${Math.max(5, extra / 20 + 4)}s`;
                t.classList.add('marquee-activo');
            }
        });
    }
    window.addEventListener('resize', activarMarquee);

    // Los nombres y descripciones los escriben usuarios: se escapan antes de insertarlos como HTML
    function esc(t) {
        return String(t ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    }

    function hace(min) {
        if (min < 60) return `${min} min`;
        return `${Math.floor(min / 60)} h ${min % 60} min`;
    }

    // ------------------------------------------------------------ bloques HTML
    function renderKpis(kpis) {
        el('kpisDashboard').innerHTML = kpis.map(k => `
            <div class="col-6 col-lg kpi-col">
                <div class="card-dash kpi-card">
                    <div class="kpi-icono bg-${k.color} bg-opacity-10 text-${k.color}"><i class="bi ${k.icono}"></i></div>
                    <div class="kpi-texto">
                        <div class="marquee-caja text-muted small" title="${esc(k.etiqueta)}"><span class="marquee-texto">${esc(k.etiqueta)}</span></div>
                        <div class="fs-4 fw-bold">${esc(k.valor)}</div>
                    </div>
                </div>
            </div>`).join('');
        activarMarquee();
    }

    function renderKV(id, items) {
        const c = el(id);
        if (!c) return;
        c.innerHTML = items.map(i => `
            <div class="kv-fila"><span class="text-muted">${esc(i.etiqueta)}</span><span class="kv-valor">${esc(i.valor)}</span></div>`).join('');
    }

    function renderSenderos(lista) {
        const c = el('listaSenderosDestacados');
        if (!c) return;
        c.innerHTML = lista.length ? lista.map((s, i) => `
            <div class="col-12 col-md-6 d-flex">
                <div class="sendero-card-dash ${i === 0 ? 'primero' : ''}">
                    <div class="sendero-card-cuerpo">
                        <img class="img-dash-grande" src="${esc(s.imagen || IMG_SENDERO)}" alt="">
                        <div class="d-flex justify-content-between gap-2">
                            <div style="min-width:0">
                                <div class="small opacity-75">Nombre:</div>
                                <div class="fw-bold text-truncate">${esc(s.nombre)}</div>
                            </div>
                            <div class="text-end flex-shrink-0">
                                <div class="small opacity-75">Longitud:</div>
                                <div class="fw-bold">${esc(s.longitud_km)} Km</div>
                            </div>
                        </div>
                    </div>
                    <div class="sendero-card-pie small">
                        <span>${s.recorridos} recorridos</span>
                        <span><span class="punto-estado" style="background:${COLOR_ESTADO_SENDERO[s.estado] || '#999'}"></span>${esc(s.estado_display)}</span>
                    </div>
                </div>
            </div>`).join('') : '<div class="col-12 text-muted small">Aún no hay senderos registrados.</div>';
    }

    // Tarjetas informativas
    function renderIncidencias(lista) {
        const c = el('listaIncidenciasRecientes');
        if (!c) return;
        c.innerHTML = lista.length ? lista.map((r, i) => `
            <div class="col-12 col-md-6 d-flex">
                <div class="sendero-card-dash ${i === 0 ? 'primero' : ''}">
                    <div class="sendero-card-cuerpo">
                        ${r.foto
                            ? `<img class="img-dash-grande" src="${esc(r.foto)}" alt="">`
                            : `<div class="img-dash-grande img-dash-vacia"><i class="bi bi-image"></i></div>`}
                        <div style="min-width:0">
                            <div class="small opacity-75">Sendero:</div>
                            <div class="fw-bold text-truncate">${esc(r.sendero_nombre)}</div>
                            <div class="small opacity-75 mt-2">Categoría:</div>
                            <div class="fw-bold text-truncate">${esc(r.categoria)}</div>
                        </div>
                    </div>
                    <div class="sendero-card-pie small"><span class="text-truncate">${esc(r.descripcion)}</span></div>
                </div>
            </div>`).join('') : '<div class="col-12 text-muted small">Aún no hay incidencias.</div>';
    }

    function renderActividad(id, lista) {
        const c = el(id);
        if (!c) return;
        if (!lista || !lista.length) {
            c.innerHTML = '<div class="text-muted small py-3">Sin actividad registrada aún.</div>';
            return;
        }
        c.innerHTML = lista.map(a => `
            <div class="actividad-item">
                <div class="actividad-icono"><i class="bi ${ICONOS_TIPO[a.tipo] || 'bi-info-circle text-muted'}"></i></div>
                <div class="flex-grow-1"><div class="fw-semibold">${esc(a.usuario)}</div><div class="small text-muted">${esc(a.fecha)}</div></div>
                <div class="small fw-semibold text-end">${esc(a.tipo_display)}</div>
            </div>`).join('');
    }

    function renderCarrusel(id, bloque) {
        const c = el(id);
        if (!c || !bloque) return;
        el(id + 'Total').textContent = bloque.total;
        c.innerHTML = bloque.items.length ? bloque.items.map(p => `
            <div class="persona-item">
                <img src="${esc(p.foto || IMG_AVATAR)}" alt="">
                <div class="small fw-semibold mt-1">${esc(p.nombre)}</div>
                <div class="small text-primary">${esc(p.subtitulo)}</div>
            </div>`).join('') : '<div class="text-muted small">Sin registros aún.</div>';
    }

    // ---------------------------------------------------------------- gráficos
    function dibujar(id, config) {
        const canvas = el(id);
        if (!canvas) return;
        if (graficos[id]) graficos[id].destroy();
        graficos[id] = new Chart(canvas, config);
    }

    const opcionesBase = {
        responsive: true, maintainAspectRatio: false,
        scales: { y: { beginAtZero: true, ticks: { precision: 0 } }, x: { grid: { display: false } } },
    };

    function dibujarGraficos(d) {
        const s = d.actividad_semanal;
        dibujar('graficoSemanal', {
            type: 'bar',
            data: { labels: s.etiquetas, datasets: [
                { label: 'Reportes', data: s.reportes, backgroundColor: '#2dd4bf', borderRadius: 8 },
                { label: 'Recorridos', data: s.recorridos, backgroundColor: '#3b82f6', borderRadius: 8 },
            ] },
            options: { ...opcionesBase, plugins: { legend: { position: 'top', align: 'end' } } },
        });

        const cats = d.incidencias_categoria;
        const hayCats = cats.some(c => c.valor > 0);
        dibujar('graficoCategorias', {
            type: 'pie',
            data: hayCats
                ? { labels: cats.map(c => `${c.etiqueta} (${c.valor})`), datasets: [{ data: cats.map(c => c.valor), backgroundColor: COLORES_CATEGORIA, borderWidth: 2, borderColor: '#fff' }] }
                : { labels: ['Sin datos'], datasets: [{ data: [1], backgroundColor: ['#e5e7eb'] }] },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' }, tooltip: { enabled: hayCats } } },
        });

        dibujar('graficoBalance', {
            type: 'line',
            data: { labels: d.balance_mensual.etiquetas, datasets: [{ label: 'Reportes', data: d.balance_mensual.valores, borderColor: '#3b82f6', backgroundColor: 'rgba(59,130,246,0.15)', fill: true, tension: 0.4, pointRadius: 3 }] },
            options: { ...opcionesBase, plugins: { legend: { display: false } } },
        });

        dibujar('graficoRegistros', {
            type: 'bar',
            data: { labels: d.registros_mensuales.etiquetas, datasets: [{ label: 'Nuevos senderistas', data: d.registros_mensuales.valores, backgroundColor: '#8b5cf6', borderRadius: 8 }] },
            options: { ...opcionesBase, plugins: { legend: { display: false } } },
        });

        dibujar('graficoRecorridos', {
            type: 'line',
            data: { labels: d.recorridos_mensuales.etiquetas, datasets: [{ label: 'Recorridos finalizados', data: d.recorridos_mensuales.valores, borderColor: '#14b8a6', backgroundColor: 'rgba(20,184,166,0.15)', fill: true, tension: 0.4, pointRadius: 3 }] },
            options: { ...opcionesBase, plugins: { legend: { display: false } } },
        });

        const salud = d.salud_senderos;
        const haySalud = salud.some(x => x.valor > 0);
        dibujar('graficoSalud', {
            type: 'doughnut',
            data: haySalud
                ? { labels: salud.map(x => `${x.etiqueta} (${x.valor})`), datasets: [{ data: salud.map(x => x.valor), backgroundColor: salud.map(x => COLOR_ESTADO_SENDERO[x.clave]), borderWidth: 2, borderColor: '#fff' }] }
                : { labels: ['Sin datos'], datasets: [{ data: [1], backgroundColor: ['#e5e7eb'] }] },
            options: { responsive: true, maintainAspectRatio: false, cutout: '60%', plugins: { legend: { position: 'bottom' }, tooltip: { enabled: haySalud } } },
        });
    }

    // -------------------------------------------------------------------- mapa
    function iniciarMapa() {
        mapa = L.map('mapaCalor').setView([-3.9973, -79.2005], 12);
        const key = window.CARTO_API_KEY || '';
        const url = key
            ? `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${key}`
            : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
        L.tileLayer(url, { attribution: '&copy; OpenStreetMap contributors &copy; CARTO', maxZoom: 19, subdomains: 'abcd' }).addTo(mapa);
        capaSinActividad = L.layerGroup().addTo(mapa);
        setTimeout(() => mapa.invalidateSize(), 200);
    }

    function renderCalor(puntos) {
        if (capaCalor) { mapa.removeLayer(capaCalor); capaCalor = null; }
        if (!puntos.length) return;
        capaCalor = L.heatLayer(puntos, {
            radius: 28, blur: 22, maxZoom: 17, minOpacity: 0.4,
            gradient: { 0.2: '#3b82f6', 0.45: '#22d3ee', 0.65: '#facc15', 0.85: '#f97316', 1: '#dc2626' },
        }).addTo(mapa);
        mapa.fitBounds(puntos.map(p => [p[0], p[1]]), { padding: [40, 40], maxZoom: 15 });
    }

    function renderSinActividad(lista, umbral) {
        el('umbralSinActividad').textContent = umbral;
        capaSinActividad.clearLayers();
        marcadores = [];
        ultimaListaSinActividad = lista;

        const c = el('listaSinActividad');
        if (!lista.length) {
            c.innerHTML = '<div class="text-success small py-2"><i class="bi bi-check-circle"></i> Ningún recorrido en curso presenta pérdida de señal GPS.</div>';
            return;
        }

        c.innerHTML = lista.map((s, i) => `
            <div class="alerta-item" data-i="${i}">
                <div>
                    <div class="fw-semibold">${esc(s.usuario)}</div>
                    <div class="small text-muted">${esc(s.sendero || 'Recorrido libre')} · última posición ${esc(s.ultima_hora)}</div>
                </div>
                <div class="text-end"><div class="fw-bold text-danger">hace ${hace(s.hace_minutos)}</div>
                    <div class="small text-muted">${s.precision_m !== null ? '±' + s.precision_m + ' m' : ''}</div></div>
            </div>`).join('');

        lista.forEach(s => {
            const m = L.circleMarker([s.lat, s.lon], { radius: 9, color: '#b91c1c', fillColor: '#ef4444', fillOpacity: 0.9, weight: 2 })
                .bindPopup(`<strong>${esc(s.usuario)}</strong><br>${esc(s.sendero || 'Recorrido libre')}<br>Última posición: ${esc(s.ultima_hora)}`)
                .addTo(capaSinActividad);
            marcadores.push(m);
        });
    }

    el('listaSinActividad').addEventListener('click', function (e) {
        const item = e.target.closest('.alerta-item');
        if (!item) return;
        const i = parseInt(item.dataset.i, 10);
        const s = ultimaListaSinActividad[i];
        mapa.setView([s.lat, s.lon], 16);
        if (marcadores[i]) marcadores[i].openPopup();
        el('mapaCalor').scrollIntoView({ behavior: 'smooth', block: 'center' });
    });

    // ------------------------------------------------------------------- carga
    async function cargar(primera) {
        try {
            const resp = await fetch(API, { credentials: 'same-origin' });
            if (!resp.ok) return;
            const d = await resp.json();

            // Estos bloques se refrescan siempre (el de "sin señal" es sensible al tiempo)
            renderKpis(d.kpis);
            renderSinActividad(d.sin_actividad, d.umbral_sin_senal_min);
            renderActividad('listaActividad', d.actividad_reciente);

            if (!primera) return;

            renderKV('sensadoOportunista', d.sensado.oportunista);
            renderKV('sensadoParticipativo', d.sensado.participativo);
            renderKV('listaComunidad', d.comunidad);
            renderSenderos(d.senderos_destacados || []);
            renderIncidencias(d.incidencias_recientes || []);
            renderActividad('listaActividadSenderistas', d.actividad_reciente_senderistas);
            renderCarrusel('carruselPrincipal', d.carrusel_principal);
            renderCarrusel('carruselSenderistas', d.carrusel_senderistas);
            dibujarGraficos(d);
            renderCalor(d.calor);
        } catch (e) {
            console.error('Error cargando el dashboard:', e);
        }
    }

    iniciarMapa();
    cargar(true);
    setInterval(() => cargar(false), INTERVALO_REFRESCO_MS);
});