document.addEventListener('DOMContentLoaded', function () {
    const API = '/api/notificaciones/panel/';
    const grid = document.getElementById('gridNotificaciones');
    const vacio = document.getElementById('mensajeVacioNotif');
    const overlay = document.getElementById('overlayNotif');
    const sidebar = document.getElementById('sidebarNotif');
    const contenido = document.getElementById('contenidoNotif');
    const titulo = document.getElementById('tituloSidebarNotif');
    const buscador = document.getElementById('buscarNotifInput');

    let lista = [];
    let actual = null;
    let opciones = { tipos: [], senderos: [], senderistas: [] };

    const esc = t => String(t ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    const csrf = () => (document.cookie.match(/csrftoken=([^;]+)/) || [])[1] || '';

    // ----------------------------------------------------------------- listado
    function tarjeta(n, i) {
        const buscable = `${n.titulo} ${n.tipo_display} ${n.fecha} ${n.destinatario_nombre}`.toLowerCase();
        return `
        <div class="col-12 col-md-6 col-xl-4 notif-item" data-buscar="${esc(buscable)}">
            <div class="notif-card ${i === 0 ? 'primero' : ''}">
                <div class="notif-img-wrap">
                    ${n.imagen ? `<img src="${esc(n.imagen)}" alt="">` : `<div class="notif-img-vacia"><i class="bi bi-bell"></i></div>`}
                    <span class="notif-chip">${esc(n.tipo_display)}</span>
                </div>
                <div class="notif-card-pie">
                    <div style="min-width:0">
                        <div class="small opacity-75">Título</div>
                        <div class="fw-semibold text-truncate">${esc(n.titulo)}</div>
                        <div class="small opacity-75 text-truncate">${esc(n.fecha)} · ${esc(n.destinatario_nombre)}</div>
                    </div>
                    <button type="button" class="btn ${i === 0 ? 'btn-light text-primary' : 'btn-primary'} px-4 btn-editar-notif" data-id="${n.id}">Editar</button>
                </div>
            </div>
        </div>`;
    }

    function cargar() {
        return fetch(API, { credentials: 'same-origin' }).then(r => r.json()).then(data => {
            lista = data;
            vacio.classList.toggle('d-none', lista.length > 0);
            grid.innerHTML = lista.map(tarjeta).join('');
            filtrar();
        });
    }

    function filtrar() {
        const q = buscador.value.trim().toLowerCase();
        grid.querySelectorAll('.notif-item').forEach(el => el.classList.toggle('d-none', !el.dataset.buscar.includes(q)));
    }
    buscador.addEventListener('input', filtrar);

    // ------------------------------------------------------------- sidebar
    function cerrar() { sidebar.classList.remove('abierto'); overlay.classList.add('d-none'); }
    overlay.addEventListener('click', cerrar);

    function abrir(n) {
        actual = n;
        titulo.textContent = n ? 'Editar Notificación' : 'Nueva Notificación';

        const tipos = opciones.tipos.map((t, i) => `
            <div class="d-flex align-items-center gap-3 mb-3">
                <input class="form-check-input switch-tipo m-0" type="radio" name="tipoNotif" id="tipo_${t.valor}" value="${t.valor}" ${(n ? n.tipo === t.valor : i === 0) ? 'checked' : ''}>
                <label class="small" for="tipo_${t.valor}" style="cursor:pointer">${esc(t.etiqueta)}</label>
            </div>`).join('');

        const optSenderistas = opciones.senderistas.map(s =>
            `<option value="${s.id}" ${n && n.destinatario_id === s.id ? 'selected' : ''}>${esc(s.nombre)} (${esc(s.email)})</option>`).join('');
        const optSenderos = opciones.senderos.map(s =>
            `<option value="${s.id}" ${n && n.sendero_id === s.id ? 'selected' : ''}>${esc(s.nombre)}</option>`).join('');
        const paraUno = n && n.destino === 'usuario';

        contenido.innerHTML = `
            <div class="notif-preview mb-3">
                <img id="imgPreviewNotif" src="${esc(n && n.imagen ? n.imagen : '')}" class="${n && n.imagen ? '' : 'd-none'}" alt="">
                <div id="vacioPreviewNotif" class="notif-preview-vacio ${n && n.imagen ? 'd-none' : ''}"><i class="bi bi-image"></i></div>
                <label class="btn-camara-notif"><i class="bi bi-camera-fill"></i><input type="file" id="inputImagenNotif" accept="image/*" hidden></label>
            </div>
            <div class="small text-muted mb-3">La imagen es opcional.</div>

            <label class="form-label small fw-semibold">Título</label>
            <input type="text" id="fNotifTitulo" maxlength="120" class="form-control form-control-pill mb-3" placeholder="Agregar título" value="${esc(n ? n.titulo : '')}">

            <label class="form-label small fw-semibold">Mensaje</label>
            <textarea id="fNotifMensaje" maxlength="1000" rows="4" class="form-control form-control-pill mb-3" placeholder="Escribe el mensaje para los senderistas">${esc(n ? n.mensaje : '')}</textarea>

            <label class="form-label small fw-semibold d-block">Tipo</label>
            <div class="mb-2">${tipos}</div>

            <label class="form-label small fw-semibold d-block">Destinatarios</label>
            <div class="d-flex gap-3 mb-2">
                <div class="form-check"><input class="form-check-input" type="radio" name="destinoNotif" id="destTodos" value="todos" ${paraUno ? '' : 'checked'}><label class="form-check-label small" for="destTodos">Todos los senderistas</label></div>
                <div class="form-check"><input class="form-check-input" type="radio" name="destinoNotif" id="destUno" value="usuario" ${paraUno ? 'checked' : ''}><label class="form-check-label small" for="destUno">Un senderista</label></div>
            </div>
            <select id="fNotifDestinatario" class="form-select form-control-pill mb-3 ${paraUno ? '' : 'd-none'}">
                <option value="">Selecciona un senderista...</option>${optSenderistas}
            </select>

            <label class="form-label small fw-semibold">Sendero relacionado (opcional)</label>
            <select id="fNotifSendero" class="form-select form-control-pill mb-4"><option value="">Ninguno</option>${optSenderos}</select>

            <div class="d-flex gap-2">
                ${n ? '<button type="button" id="btnEliminarNotif" class="btn btn-eliminar rounded-3 flex-fill py-2">Eliminar</button>' : ''}
                <button type="button" id="btnGuardarNotif" class="btn btn-primary rounded-3 flex-fill py-2">Guardar</button>
            </div>`;

        contenido.querySelectorAll('input[name="destinoNotif"]').forEach(r =>
            r.addEventListener('change', () => document.getElementById('fNotifDestinatario').classList.toggle('d-none', r.value !== 'usuario' || !r.checked)));

        document.getElementById('inputImagenNotif').addEventListener('change', function () {
            const f = this.files[0];
            if (!f) return;
            const img = document.getElementById('imgPreviewNotif');
            img.src = URL.createObjectURL(f);
            img.classList.remove('d-none');
            document.getElementById('vacioPreviewNotif').classList.add('d-none');
        });

        document.getElementById('btnGuardarNotif').addEventListener('click', guardar);
        const del = document.getElementById('btnEliminarNotif');
        if (del) del.addEventListener('click', eliminar);

        sidebar.classList.add('abierto');
        overlay.classList.remove('d-none');
    }

    // ---------------------------------------------------------- guardar / eliminar
    function guardar() {
        const btn = document.getElementById('btnGuardarNotif');
        const original = btn.innerHTML;
        const destino = contenido.querySelector('input[name="destinoNotif"]:checked').value;

        const fd = new FormData();
        fd.append('titulo', document.getElementById('fNotifTitulo').value);
        fd.append('mensaje', document.getElementById('fNotifMensaje').value);
        fd.append('tipo', contenido.querySelector('input[name="tipoNotif"]:checked').value);
        fd.append('destino', destino);
        if (destino === 'usuario') fd.append('destinatario', document.getElementById('fNotifDestinatario').value);
        fd.append('sendero', document.getElementById('fNotifSendero').value);
        const file = document.getElementById('inputImagenNotif').files[0];
        if (file) fd.append('imagen', file);

        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Guardando...';

        fetch(actual ? `${API}${actual.id}/` : API, { method: 'POST', credentials: 'same-origin', headers: { 'X-CSRFToken': csrf() }, body: fd })
            .then(r => r.json().then(data => ({ ok: r.ok, data })))
            .then(({ ok, data }) => {
                if (!ok) { alert(data.message || 'No se pudo guardar.'); btn.disabled = false; btn.innerHTML = original; return; }
                cerrar();
                cargar();
            })
            .catch(() => { alert('Error de conexión.'); btn.disabled = false; btn.innerHTML = original; });
    }

    function eliminar() {
        if (!confirm('¿Eliminar esta notificación? Dejará de verse en la app de los senderistas.')) return;
        fetch(`${API}${actual.id}/`, { method: 'DELETE', credentials: 'same-origin', headers: { 'X-CSRFToken': csrf() } })
            .then(() => { cerrar(); cargar(); });
    }

    // ------------------------------------------------------------------- eventos
    grid.addEventListener('click', e => {
        const btn = e.target.closest('.btn-editar-notif');
        if (btn) abrir(lista.find(n => n.id === parseInt(btn.dataset.id, 10)));
    });
    document.getElementById('btnNuevaNotificacion').addEventListener('click', () => abrir(null));

    fetch(API + 'opciones/', { credentials: 'same-origin' }).then(r => r.json()).then(o => { opciones = o; });
    cargar();
});