document.addEventListener('DOMContentLoaded', function () {
    const API_URL = window.HISTORIAL_API;
    const PDF_URL = window.HISTORIAL_PDF;
    const tbody = document.getElementById('cuerpoTablaHistorial');
    const overlay = document.getElementById('overlayHistorial');
    const tarjeta = document.getElementById('tarjetaHistorial');
    const filtroDesde = document.getElementById('filtroDesde');
    const filtroHasta = document.getElementById('filtroHasta');
    const btnPdf = document.getElementById('btnDescargarPdf');

    const inputBuscarActividad = document.getElementById('buscarActividadInput');

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

    function urlConFiltros(base) {
        const params = new URLSearchParams();
        if (filtroDesde.value) params.append('desde', filtroDesde.value);
        if (filtroHasta.value) params.append('hasta', filtroHasta.value);
        const query = params.toString();
        return query ? `${base}?${query}` : base;
    }

    function aplicarFiltroTexto() {
        const filtro = inputBuscarActividad ? inputBuscarActividad.value.trim().toLowerCase() : '';
        tbody.querySelectorAll('tr').forEach(row => {
            row.style.display = row.dataset.buscar.includes(filtro) ? '' : 'none';
        });
    }

    if (inputBuscarActividad) {
        inputBuscarActividad.addEventListener('input', aplicarFiltroTexto);
    }

    function cargarHistorial() {
        fetch(urlConFiltros(API_URL), { credentials: 'same-origin' })
            .then(r => r.json())
            .then(data => {
                tbody.innerHTML = '';
                data.forEach(a => {
                    const icono = ICONOS_TIPO[a.tipo] || 'bi-info-circle text-muted';
                    const tr = document.createElement('tr');
                    
                    // Guarda los campos concatenados para el filtrado rápido por texto
                    tr.dataset.buscar = `${a.tipo_display} ${a.fecha} ${a.usuario_nombre}`.toLowerCase();

                    tr.innerHTML = `
                        <td><i class="bi ${icono} fs-5"></i></td>
                        <td>${a.tipo_display}</td>
                        <td>${a.fecha}</td>
                        <td>${a.usuario_nombre}</td>
                        <td><button type="button" class="btn btn-outline-primary btn-sm rounded-pill btn-ver-actividad" data-json='${JSON.stringify(a).replace(/'/g, "&#39;")}'>Ver</button></td>
                    `;
                    tbody.appendChild(tr);
                });

                // Re-aplica el filtro si el usuario ya tenía texto escrito al cambiar fechas/recargar
                aplicarFiltroTexto();
            });
    }

    tbody.addEventListener('click', function (e) {
        const btn = e.target.closest('.btn-ver-actividad');
        if (!btn) return;
        const a = JSON.parse(btn.dataset.json);
        tarjeta.innerHTML = `
            <h5 class="fw-bold mb-3">${a.tipo_display}</h5>
            <p class="mb-1"><strong>Usuario:</strong> ${a.usuario_nombre}</p>
            <p class="mb-1"><strong>Fecha y hora:</strong> ${a.fecha}</p>
            <p class="mb-3"><strong>Detalle:</strong> ${a.descripcion || 'Sin detalle adicional'}</p>
            <button type="button" class="btn btn-primary rounded-pill w-100" id="btnCerrarTarjetaHistorial">Cerrar</button>
        `;
        tarjeta.classList.remove('d-none');
        overlay.classList.remove('d-none');
    });

    overlay.addEventListener('click', cerrarTarjeta);
    tarjeta.addEventListener('click', function (e) {
        if (e.target.id === 'btnCerrarTarjetaHistorial') cerrarTarjeta();
    });
    function cerrarTarjeta() { tarjeta.classList.add('d-none'); overlay.classList.add('d-none'); }

    filtroDesde.addEventListener('change', cargarHistorial);
    filtroHasta.addEventListener('change', cargarHistorial);
    btnPdf.addEventListener('click', function (e) {
        e.preventDefault();
        window.location.href = urlConFiltros(PDF_URL);
    });

    cargarHistorial();
});