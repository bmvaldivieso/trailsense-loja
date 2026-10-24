document.addEventListener('DOMContentLoaded', function () {
    console.log('Vista Senderos lista cargada.');

    const input = document.getElementById('buscarSenderoInput');
    const items = document.querySelectorAll('.sendero-item');

    // Llegada desde la campana (?estado=critico): solo críticos, resaltados
    const aviso = document.getElementById('avisoFiltroSenderos');
    if (new URLSearchParams(window.location.search).get('estado') === 'critico' && aviso) {
        let total = 0;
        items.forEach(function (item) {
            const esCritico = item.dataset.estado === 'critico';
            item.classList.toggle('d-none', !esCritico);
            if (esCritico) { item.querySelector('.card').classList.add('tarjeta-resaltada'); total++; }
        });
        aviso.innerHTML = `<span><i class="bi bi-exclamation-triangle me-2"></i>Mostrando ${total} sendero(s) en estado crítico.</span>
                           <a href="${window.location.pathname}" class="alert-link">Ver todos</a>`;
        aviso.classList.remove('d-none');
        const primero = document.querySelector('.sendero-item:not(.d-none)');
        if (primero) primero.scrollIntoView({ behavior: 'smooth', block: 'center' });
        if (window.activarMarquee) window.activarMarquee();
    }
    
    if (!input) return;

    input.addEventListener('input', function () {
        const filtro = this.value.trim().toLowerCase();

        items.forEach(function (item) {
            const nombre = item.getAttribute('data-nombre') || '';
            item.style.display = nombre.includes(filtro) ? '' : 'none';
        });
    });
});