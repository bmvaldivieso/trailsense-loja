document.addEventListener('DOMContentLoaded', function () {
    const IMG_PLACEHOLDER = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

    const sidebar = document.getElementById('sidebarDetalleAdmin');
    const overlay = document.getElementById('overlayDetalleAdmin');
    const contenido = document.getElementById('contenidoDetalleAdmin');
    let adminActualId = null;

    function cerrarDetalle() { sidebar.classList.remove('abierto'); overlay.classList.add('d-none'); }
    overlay.addEventListener('click', cerrarDetalle);

    function obtenerCsrfToken() {
        const match = document.cookie.match(/csrftoken=([^;]+)/);
        return match ? match[1] : '';
    }

    const tabla = $('#tablaAdmins').DataTable({
        language: {
            search: "Buscar:",
            lengthMenu: "Mostrar _MENU_ registros",
            info: "Mostrando _START_ a _END_ de _TOTAL_ registros",
            paginate: { previous: "Anterior", next: "Siguiente" },
            zeroRecords: "No se encontraron administradores",
        },
        columns: [
            { data: 'foto', render: foto => `<img src="${foto || IMG_PLACEHOLDER}" class="foto-tabla">` },
            { data: 'nombre' },
            { data: 'total_notificaciones' },
            { data: 'total_senderos' },
            { data: 'email' },
            {
                data: 'id',
                render: id => `<button type="button" class="btn btn-outline-primary btn-sm rounded-pill btn-editar-admin" data-id="${id}">Editar</button>`,
            },
        ],
    });

    function cargarListado() {
        fetch('/api/auth/panel/admins/listado/', { credentials: 'same-origin' })
            .then(r => r.json())
            .then(data => {
                document.getElementById('indTotalAdmins').textContent = data.length;
                document.getElementById('indTotalNotificaciones').textContent = data.reduce((acc, a) => acc + a.total_notificaciones, 0);
                document.getElementById('indTotalSenderos').textContent = data.reduce((acc, a) => acc + a.total_senderos, 0);

                tabla.clear();
                tabla.rows.add(data);
                tabla.draw();
            });
    }

    $('#tablaAdmins tbody').on('click', '.btn-editar-admin', function () {
        abrirDetalle(parseInt($(this).data('id'), 10));
    });

    document.getElementById('btnNuevoAdmin').addEventListener('click', () => abrirDetalle(null));

    function abrirDetalle(id) {
        adminActualId = id;
        sidebar.classList.add('abierto');
        overlay.classList.remove('d-none');

        if (id === null) { renderizarFormulario({}); return; }
        fetch(`/api/auth/panel/admins/${id}/`, { credentials: 'same-origin' })
            .then(r => r.json())
            .then(renderizarFormulario);
    }

    function renderizarFormulario(a) {
        contenido.innerHTML = `
            <div class="text-center mb-3">
                <div class="position-relative d-inline-block">
                    <img id="previewFotoAdmin" src="${a.foto || IMG_PLACEHOLDER}" class="foto-perfil-detalle">
                    <label class="btn btn-primary btn-camara-perfil position-absolute bottom-0 end-0" style="cursor:pointer;">
                        <i class="bi bi-camera-fill"></i>
                        <input type="file" id="inputFotoAdmin" accept="image/*" hidden>
                    </label>
                </div>
            </div>
            <label class="form-label small fw-semibold">Nombres</label>
            <input type="text" id="fAdminNombre" class="form-control form-control-pill mb-2" value="${a.first_name || ''}">
            <label class="form-label small fw-semibold">Apellidos</label>
            <input type="text" id="fAdminApellido" class="form-control form-control-pill mb-2" value="${a.last_name || ''}">
            <label class="form-label small fw-semibold">Correo</label>
            <input type="email" id="fAdminCorreo" class="form-control form-control-pill mb-2" value="${a.email || ''}" ${adminActualId ? 'readonly' : ''}>
            ${!adminActualId ? `
            <label class="form-label small fw-semibold">Contraseña</label>
            <input type="password" id="fAdminPassword" class="form-control form-control-pill mb-2" placeholder="Mínimo 8 caracteres">` : ''}
            <label class="form-label small fw-semibold">Rol</label>
            <input type="text" class="form-control form-control-pill mb-2" value="Administrador" readonly disabled>
            <label class="form-label small fw-semibold">Fecha Registro</label>
            <input type="text" class="form-control form-control-pill mb-2" value="${a.fecha_registro || 'Se asigna al crear'}" readonly disabled>
            <label class="form-label small fw-semibold">Activo</label>
            <select id="fAdminActivo" class="form-select form-control-pill mb-2">
                <option value="true" ${a.is_active !== false ? 'selected' : ''}>Sí</option>
                <option value="false" ${a.is_active === false ? 'selected' : ''}>No</option>
            </select>
            <label class="form-label small fw-semibold">Permiso Senderos</label>
            <select id="fAdminPermisoSenderos" class="form-select form-control-pill mb-2">
                <option value="true" ${a.is_staff ? 'selected' : ''}>Sí</option>
                <option value="false" ${!a.is_staff ? 'selected' : ''}>No</option>
            </select>
            <label class="form-label small fw-semibold">Cedula</label>
            <input type="text" id="fAdminCedula" class="form-control form-control-pill mb-2" value="${a.cedula || ''}">
            <label class="form-label small fw-semibold">Reputacion</label>
            <input type="text" class="form-control form-control-pill mb-3" value="${a.reputacion_score ?? 0}" readonly disabled>
            <div class="d-flex gap-2">
                ${adminActualId ? `<button type="button" id="btnEliminarAdmin" class="btn btn-eliminar rounded-pill flex-fill">Eliminar</button>` : ''}
                <button type="button" id="btnGuardarAdmin" class="btn btn-primary rounded-pill flex-fill">Guardar</button>
            </div>
        `;

        document.getElementById('btnGuardarAdmin').addEventListener('click', guardarAdmin);
        const btnEliminar = document.getElementById('btnEliminarAdmin');
        if (btnEliminar) btnEliminar.addEventListener('click', eliminarAdmin);
        document.getElementById('inputFotoAdmin').addEventListener('change', function (e) {
            const file = e.target.files[0];
            if (file) document.getElementById('previewFotoAdmin').src = URL.createObjectURL(file);
        });
    }

    function guardarAdmin() {
        const btn = document.getElementById('btnGuardarAdmin');
        const textoOriginal = btn.innerHTML;
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Guardando...';

        const formData = new FormData();
        formData.append('first_name', document.getElementById('fAdminNombre').value);
        formData.append('last_name', document.getElementById('fAdminApellido').value);
        formData.append('cedula', document.getElementById('fAdminCedula').value);
        formData.append('is_active', document.getElementById('fAdminActivo').value);
        formData.append('is_staff', document.getElementById('fAdminPermisoSenderos').value);
        if (!adminActualId) {
            formData.append('email', document.getElementById('fAdminCorreo').value);
            formData.append('password', document.getElementById('fAdminPassword').value);
        }
        const inputFoto = document.getElementById('inputFotoAdmin');
        if (inputFoto.files[0]) formData.append('foto_perfil', inputFoto.files[0]);

        const url = adminActualId ? `/api/auth/panel/admins/${adminActualId}/` : '/api/auth/panel/admins/';
        fetch(url, { method: 'POST', credentials: 'same-origin', headers: { 'X-CSRFToken': obtenerCsrfToken() }, body: formData })
            .then(r => r.json().then(data => ({ ok: r.ok, data })))
            .then(({ ok, data }) => {
                if (!ok) {
                    alert(data.message || 'No se pudo guardar.');
                    btn.disabled = false;
                    btn.innerHTML = textoOriginal;
                    return;
                }
                cerrarDetalle();
                cargarListado();
            })
            .catch(() => {
                alert('Error de conexión.');
                btn.disabled = false;
                btn.innerHTML = textoOriginal;
            });
    }

    function eliminarAdmin() {
        if (!confirm('¿Eliminar este administrador permanentemente?')) return;
        fetch(`/api/auth/panel/admins/${adminActualId}/`, { method: 'DELETE', credentials: 'same-origin', headers: { 'X-CSRFToken': obtenerCsrfToken() } })
            .then(() => { cerrarDetalle(); cargarListado(); });
    }

    cargarListado();
});