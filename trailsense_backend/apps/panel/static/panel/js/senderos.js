document.addEventListener('DOMContentLoaded', function () {
    console.log('Vista Senderos lista cargada.');

    const input = document.getElementById('buscarSenderoInput');
    const items = document.querySelectorAll('.sendero-item');

    if (!input) return;

    input.addEventListener('input', function () {
        const filtro = this.value.trim().toLowerCase();

        items.forEach(function (item) {
            const nombre = item.getAttribute('data-nombre') || '';
            item.style.display = nombre.includes(filtro) ? '' : 'none';
        });
    });
});