document.addEventListener('DOMContentLoaded', function () {
    fetch('/api/reportes/panel/', { credentials: 'same-origin' })
        .then(resp => resp.json())
        .then(data => {
            document.getElementById('indTotal').textContent = data.contadores.total;
            document.getElementById('indPendientes').textContent = data.contadores.pendientes;
            document.getElementById('indRechazadas').textContent = data.contadores.rechazados;
            document.getElementById('indAprobadas').textContent = data.contadores.aprobados;

            const tbody = document.getElementById('cuerpoTablaIncidencias');
            data.reportes.forEach(r => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>${String(r.id).padStart(2, '0')}</td>
                    <td>${r.usuario_nombre}</td>
                    <td>${r.sendero_nombre}</td>
                    <td>${r.categoria}</td>
                    <td>${capitalizar(r.estado)}</td>
                    <td>${r.fecha_creacion}</td>
                    <td>
                        <button type="button" class="btn btn-light btn-gps-visual me-2" title="Ubicación" disabled>
                            <i class="bi bi-geo-alt"></i>
                        </button>
                        <a href="/panel/incidencias/${r.id}/" class="btn btn-outline-primary btn-sm rounded-pill">Ver Detalles</a>
                    </td>
                `;
                tbody.appendChild(tr);
            });

            $('#tablaIncidencias').DataTable({
                language: {
                    search: "Buscar:",
                    lengthMenu: "Mostrar _MENU_ registros",
                    info: "Mostrando _START_ a _END_ de _TOTAL_ registros",
                    paginate: { previous: "Anterior", next: "Siguiente" },
                    zeroRecords: "No se encontraron incidencias",
                },
            });
        });

    function capitalizar(texto) {
        return texto.charAt(0).toUpperCase() + texto.slice(1);
    }
});