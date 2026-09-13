document.addEventListener('DOMContentLoaded', function () {
    const listaUsuarios = document.getElementById('listaUsuarios');
    const mensajeVacio = document.getElementById('mensajeVacio');
    const sidebarDetalle = document.getElementById('sidebarDetalle');
    const overlayDetalle = document.getElementById('overlayDetalle');
    const contenidoDetalle = document.getElementById('contenidoDetalle');

    const URL_LISTA = '/api/sesiones/panel/';
    const URL_DETALLE = '/api/sesiones/panel/';
    const INTERVALO_REFRESCO_MS = 15000;

    const IMG_GENERICA = 'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=300&q=80';
    const IMG_AVATAR_DEFAULT = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

    let mapaDetalle = null;
    let idsRenderizados = new Set();

    // Incluye segundos
    function formatearDuracion(segundos) {
        const h = Math.floor(segundos / 3600);
        const m = Math.floor((segundos % 3600) / 60);
        const s = segundos % 60;
        return h > 0 ? `${h}h ${m}min ${s}s` : `${m}min ${s}s`;
    }

    function crearTarjetaRecorrido(recorrido) {
        const esValido = recorrido.estado === 'finalizada';

        const div = document.createElement('div');
        div.className = 'recorrido-card' + (esValido ? '' : ' recorrido-invalido d-none');   // Oculto por defecto si no es válido
        div.dataset.fecha = recorrido.fecha.toLowerCase();
        div.dataset.sendero = (recorrido.sendero_nombre || '').toLowerCase();
        div.dataset.estado = recorrido.estado;

        const etiquetaEstado = !esValido
            ? `<span class="badge-estado-invalido">${recorrido.estado === 'en_curso' ? 'En curso' : 'Pausada'}</span>`
            : '';

        div.innerHTML = `
            <div class="d-flex justify-content-between align-items-center small text-muted mb-1">
                <span class="badge-recorrido-numero">#${recorrido.id}</span>
                <span>${recorrido.fecha}</span>
            </div>
            <div class="fw-semibold text-primary small mb-1">${recorrido.distancia_km ?? 0} km</div>
            ${etiquetaEstado}
            <div class="recorrido-card-img-wrapper">
                <img src="${IMG_GENERICA}" alt="Recorrido">
                <button type="button" class="btn btn-primary btn-sm rounded-pill btn-detalle-recorrido" data-id="${recorrido.id}">
                    Detalle
                </button>
            </div>
        `;
        return div;
    }

    function crearTarjetaUsuario(usuario) {
        const div = document.createElement('div');
        div.className = 'usuario-card d-flex flex-column flex-md-row align-items-center gap-3';

        const scrollDiv = document.createElement('div');
        scrollDiv.className = 'recorridos-scroll flex-grow-1';
        usuario.recorridos.forEach(r => scrollDiv.appendChild(crearTarjetaRecorrido(r)));

        const inputId = `buscador-usuario-${usuario.usuario_id}`;
        const btnToggleId = `btn-toggle-invalidos-${usuario.usuario_id}`;

        // Cuenta cuántas sesiones no válidas tiene este usuario para decidir si mostrar el botón
        const totalInvalidos = usuario.recorridos.filter(r => r.estado !== 'finalizada').length;

        div.innerHTML = `
            <div class="usuario-header">
                <div class="d-flex align-items-center gap-2">
                    <img src="${usuario.usuario_foto || IMG_AVATAR_DEFAULT}" alt="${usuario.usuario_nombre}">
                    <div class="fw-bold text-dark">${usuario.usuario_nombre}</div>
                </div>
                <input type="text" id="${inputId}" class="form-control form-control-sm rounded-pill buscador-usuario" placeholder="Buscar por fecha o sendero...">
                ${totalInvalidos > 0 ? `
                    <button type="button" id="${btnToggleId}" class="btn btn-sm btn-outline-secondary rounded-pill btn-toggle-invalidos" data-mostrando="false">
                        Ver no válidos (${totalInvalidos})
                    </button>
                ` : ''}
            </div>
        `;
        div.appendChild(scrollDiv);

        div.querySelector(`#${inputId}`).addEventListener('input', function () {
            const filtro = this.value.trim().toLowerCase();
            scrollDiv.querySelectorAll('.recorrido-card').forEach(card => {
                const coincide = card.dataset.fecha.includes(filtro) || card.dataset.sendero.includes(filtro);
                card.style.display = coincide ? '' : 'none';
            });
        });

        // Alterna la visibilidad de las tarjetas marcadas como no válidas
        const btnToggle = div.querySelector(`#${btnToggleId}`);
        if (btnToggle) {
            btnToggle.addEventListener('click', function () {
                const mostrando = this.dataset.mostrando === 'true';
                scrollDiv.querySelectorAll('.recorrido-invalido').forEach(card => {
                    card.classList.toggle('d-none', mostrando);
                });
                this.dataset.mostrando = (!mostrando).toString();
                this.textContent = !mostrando ? `Ocultar no válidos (${totalInvalidos})` : `Ver no válidos (${totalInvalidos})`;
            });
        }

        return div;
    }

    async function cargarListado() {
        try {
            const resp = await fetch(URL_LISTA, { credentials: 'same-origin' });
            if (!resp.ok) return;
            const usuarios = await resp.json();

            if (usuarios.length === 0) {
                mensajeVacio.classList.remove('d-none');
                listaUsuarios.innerHTML = '';
                idsRenderizados.clear();
                return;
            }
            mensajeVacio.classList.add('d-none');

            const idsActuales = new Set();
            usuarios.forEach(u => u.recorridos.forEach(r => idsActuales.add(r.id)));

            const huboCambio =
                idsActuales.size !== idsRenderizados.size ||
                [...idsActuales].some(id => !idsRenderizados.has(id));

            if (!huboCambio) return;

            idsRenderizados = idsActuales;
            listaUsuarios.innerHTML = '';
            usuarios.forEach(u => listaUsuarios.appendChild(crearTarjetaUsuario(u)));
        } catch (e) {
            console.error('Error cargando recorridos:', e);
        }
    }

    async function abrirDetalle(id) {
        contenidoDetalle.innerHTML = '<div class="text-center py-5"><span class="spinner-border"></span></div>';
        sidebarDetalle.classList.add('abierto');
        overlayDetalle.classList.remove('d-none');

        try {
            const resp = await fetch(`${URL_DETALLE}${id}/`, { credentials: 'same-origin' });
            if (!resp.ok) {
                contenidoDetalle.innerHTML = '<div class="text-danger p-3">No se pudo cargar el recorrido.</div>';
                return;
            }
            renderizarDetalle(await resp.json());
        } catch (e) {
            contenidoDetalle.innerHTML = '<div class="text-danger p-3">Error de conexión.</div>';
        }
    }

    function renderizarDetalle(data) {
        const nombreSendero = data.sendero_nombre || 'Recorrido libre';   // Indica vínculo con sendero

        contenidoDetalle.innerHTML = `
            <div id="mapaDetalleRecorrido" class="mapa-detalle-recorrido rounded-4 mb-3"></div>

            <div class="d-flex align-items-center justify-content-center gap-2 mb-2">
                <img src="${data.usuario_foto || IMG_AVATAR_DEFAULT}" style="width:36px;height:36px;border-radius:50%;object-fit:cover;">
                <div class="fw-bold">${data.usuario_nombre}</div>
            </div>

            <div class="text-center mb-1">
                <span class="badge-recorrido-numero">Recorrido #${data.id}</span>
            </div>
            <h5 class="fw-bold text-dark text-center mb-3">${nombreSendero}</h5>

            <div class="stats-grid-detalle">
                <div class="stat-item">
                    <div class="stat-icon" style="background:#fee2e2;">
                        <i class="bi bi-geo-alt-fill text-danger fs-5"></i>
                    </div>
                    <div class="stat-valor">${data.distancia_km} km</div>
                    <div class="text-muted small">Distancia</div>
                </div>
                <div class="stat-item">
                    <div class="stat-icon" style="background:#fde8ec;">
                        <i class="bi bi-stopwatch-fill fs-5" style="color:#9d174d;"></i>
                    </div>
                    <div class="stat-valor">${formatearDuracion(data.duracion_segundos)}</div>
                    <div class="text-muted small">Duración</div>
                </div>
                <div class="stat-item">
                    <div class="stat-icon" style="background:#dbeafe;">
                        <i class="bi bi-speedometer2 text-primary fs-5"></i>
                    </div>
                    <div class="stat-valor">${data.velocidad_promedio_kmh} km/h</div>
                    <div class="text-muted small">Velocidad prom.</div>
                </div>
                <div class="stat-item">
                    <div class="stat-icon" style="background:#fef3c7;">
                        <i class="bi bi-person-walking fs-5" style="color:#b45309;"></i>
                    </div>
                    <div class="stat-valor">${data.pasos}</div>
                    <div class="text-muted small">Pasos</div>
                </div>
            </div>

            <div class="text-center mt-3">
                <button type="button" class="btn btn-primary btn-cerrar-detalle-recorrido px-5">Cerrar</button>
            </div>
        `;

        setTimeout(() => {
            if (mapaDetalle) { mapaDetalle.remove(); mapaDetalle = null; }

            const contenedor = document.getElementById('mapaDetalleRecorrido');
            if (!contenedor) return;

            const centro = (data.traza && data.traza.length > 0) ? data.traza[0] : [-3.9973, -79.2005];
            mapaDetalle = L.map('mapaDetalleRecorrido').setView(centro, 14);

            const cartoKey = window.CARTO_API_KEY || '';
            const tileUrl = cartoKey
                ? `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${cartoKey}`
                : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

            L.tileLayer(tileUrl, {
                attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
                maxZoom: 19,
                subdomains: 'abcd',
            }).addTo(mapaDetalle);

            if (data.traza && data.traza.length > 1) {
                const linea = L.polyline(data.traza, { color: '#3b82f6', weight: 4 }).addTo(mapaDetalle);
                mapaDetalle.fitBounds(linea.getBounds(), { padding: [20, 20] });
            }

            setTimeout(() => mapaDetalle.invalidateSize(), 150);
        }, 50);
    }

    function cerrarDetalle() {
        sidebarDetalle.classList.remove('abierto');
        overlayDetalle.classList.add('d-none');
    }

    listaUsuarios.addEventListener('click', function (e) {
        const btn = e.target.closest('.btn-detalle-recorrido');
        if (btn) abrirDetalle(btn.dataset.id);
    });

    // El botón "Cerrar" se crea dinámicamente dentro de contenidoDetalle,
    // por eso el listener se delega desde el contenedor en vez de buscar un id fijo.
    contenidoDetalle.addEventListener('click', function (e) {
        if (e.target.closest('.btn-cerrar-detalle-recorrido')) cerrarDetalle();
    });

    overlayDetalle.addEventListener('click', cerrarDetalle);

    cargarListado();
    setInterval(cargarListado, INTERVALO_REFRESCO_MS);
});