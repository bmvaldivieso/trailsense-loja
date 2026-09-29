document.addEventListener('DOMContentLoaded', function () {
    const IMG_PLACEHOLDER = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
    const sidebar = document.getElementById('sidebarDetalleSenderista');
    const overlay = document.getElementById('overlayDetalleSenderista');
    const contenido = document.getElementById('contenidoDetalleSenderista');

    function cerrarDetalle() { sidebar.classList.remove('abierto'); overlay.classList.add('d-none'); }
    overlay.addEventListener('click', cerrarDetalle);

    fetch('/api/auth/panel/senderistas/', { credentials: 'same-origin' })
        .then(r => r.json())
        .then(data => {
            document.getElementById('indTotalSenderistas').textContent = data.total_senderistas;
            document.getElementById('indTotalIncidencias').textContent = data.total_incidencias;
            document.getElementById('indTotalRecorridos').textContent = data.total_recorridos;

            const tbody = document.getElementById('cuerpoTablaSenderistas');
            data.senderistas.forEach(s => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td><img src="${s.foto || IMG_PLACEHOLDER}" class="foto-tabla"></td>
                    <td>${s.nombre}</td>
                    <td>${s.total_reportes}</td>
                    <td>${s.total_recorridos}</td>
                    <td>${s.email}</td>
                    <td><button type="button" class="btn btn-outline-primary btn-sm rounded-pill btn-ver-senderista" data-id="${s.id}">Ver Detalles</button></td>
                `;
                tbody.appendChild(tr);
            });

            $('#tablaSenderistas').DataTable({
                language: { search: "Buscar:", lengthMenu: "Mostrar _MENU_ registros", info: "Mostrando _START_ a _END_", paginate: { previous: "Anterior", next: "Siguiente" }, zeroRecords: "Sin resultados" },
            });
        });

    document.getElementById('cuerpoTablaSenderistas').addEventListener('click', function (e) {
        const btn = e.target.closest('.btn-ver-senderista');
        if (btn) abrirDetalle(btn.dataset.id);
    });

    function abrirDetalle(id) {
        sidebar.classList.add('abierto');
        overlay.classList.remove('d-none');
        contenido.innerHTML = '<div class="text-center py-5"><span class="spinner-border"></span></div>';

        fetch(`/api/auth/panel/senderistas/${id}/`, { credentials: 'same-origin' })
            .then(r => r.json())
            .then(s => {
                contenido.innerHTML = `
                    <div class="text-center mb-3"><img src="${s.foto || IMG_PLACEHOLDER}" class="foto-perfil-detalle"></div>
                    <label class="form-label small fw-semibold">Nombres</label>
                    <input type="text" class="form-control form-control-pill mb-2" value="${s.nombre || ''}" readonly disabled>
                    <label class="form-label small fw-semibold">Apellidos</label>
                    <input type="text" class="form-control form-control-pill mb-2" value="${s.apellido || ''}" readonly disabled>
                    <label class="form-label small fw-semibold">Correo</label>
                    <input type="text" class="form-control form-control-pill mb-2" value="${s.email}" readonly disabled>
                    <label class="form-label small fw-semibold">Fecha Registro</label>
                    <input type="text" class="form-control form-control-pill mb-2" value="${s.fecha_registro}" readonly disabled>
                    <label class="form-label small fw-semibold">Activo</label>
                    <input type="text" class="form-control form-control-pill mb-2" value="${s.is_active ? 'Sí' : 'No'}" readonly disabled>
                    <label class="form-label small fw-semibold">Cedula</label>
                    <input type="text" class="form-control form-control-pill mb-2" value="${s.cedula || 'No registrada'}" readonly disabled>
                    <label class="form-label small fw-semibold">Kilómetros recorridos</label>
                    <input type="text" class="form-control form-control-pill mb-2" value="${s.kilometros_recorridos} km" readonly disabled>
                    <label class="form-label small fw-semibold">Reputacion</label>
                    <input type="text" class="form-control form-control-pill mb-3" value="${s.reputacion_score}" readonly disabled>
                    <button type="button" class="btn btn-primary rounded-pill w-100 btn-cerrar-detalle-senderista">Cerrar</button>
                `;
            });
    }

    contenido.addEventListener('click', function (e) {
        if (e.target.closest('.btn-cerrar-detalle-senderista')) cerrarDetalle();
    });
});