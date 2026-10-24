document.addEventListener('DOMContentLoaded', function () {
    const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

    function crearDropdown(contenedor, clase) {
        const d = document.createElement('div');
        d.className = 'topbar-dropdown d-none ' + clase;
        contenedor.appendChild(d);
        return d;
    }

    // Cierra un desplegable al hacer clic fuera de su contenedor o con Esc (sin interferir con otros)
    function cerrarAfuera(contenedor, panel) {
        document.addEventListener('click', e => { if (!contenedor.contains(e.target)) panel.classList.add('d-none'); });
        document.addEventListener('keydown', e => { if (e.key === 'Escape') panel.classList.add('d-none'); });
    }

    // ------------------------------------------------------------- buscador
    const buscador = document.getElementById('buscadorGlobal');
    if (buscador) {
        const cont = buscador.parentElement;
        const panel = crearDropdown(cont, 'topbar-dropdown-buscador');
        
        // Texto de ayuda: se oculta al escribir y se desplaza solo si no cabe
        const ayuda = cont.querySelector('.buscador-ayuda');
        function actualizarAyuda() {
            cont.classList.toggle('con-texto', buscador.value.length > 0);
            if (!ayuda) return;
            const texto = ayuda.querySelector('.buscador-ayuda-texto');
            ayuda.classList.remove('desplazando');
            const exceso = texto.scrollWidth - ayuda.clientWidth;
            if (exceso > 4) {
                ayuda.style.setProperty('--desp', `-${exceso + 8}px`);
                ayuda.style.setProperty('--dur', `${Math.max(4, (exceso + 8) / 30)}s`);   // ~30 px/s
                ayuda.classList.add('desplazando');
            }
        }
        buscador.addEventListener('input', actualizarAyuda);
        window.addEventListener('resize', actualizarAyuda);
        if (document.fonts && document.fonts.ready) document.fonts.ready.then(actualizarAyuda);
        actualizarAyuda();

        let temporizador = null, ultima = 0;

        async function buscar(q) {
            const id = ++ultima;
            try {
                const resp = await fetch(buscador.dataset.url + '?q=' + encodeURIComponent(q), { credentials: 'same-origin' });
                if (!resp.ok || id !== ultima) return;
                pintar((await resp.json()).grupos);
            } catch (e) { /* sin conexión: no se muestra nada */ }
        }

        function pintar(grupos) {
            panel.classList.remove('d-none');
            if (!grupos.length) { panel.innerHTML = '<div class="p-3 small text-muted">Sin resultados</div>'; return; }
            panel.innerHTML = grupos.map(g => `
                <div class="topbar-grupo"><i class="bi ${g.icono} me-1"></i>${esc(g.nombre)}</div>
                ${g.items.map(i => `<a class="topbar-item" href="${esc(i.url)}">
                    <div class="fw-semibold">${esc(i.titulo)}</div>
                    <div class="small text-muted text-truncate">${esc(i.detalle)}</div></a>`).join('')}`).join('');
        }

        buscador.addEventListener('input', function () {
            clearTimeout(temporizador);
            const q = buscador.value.trim();
            if (q.length < 2) { panel.classList.add('d-none'); return; }
            temporizador = setTimeout(() => buscar(q), 300);
        });
        buscador.addEventListener('focus', () => { if (panel.innerHTML) panel.classList.remove('d-none'); });
        cerrarAfuera(cont, panel);
    }

    // --------------------------------------------------------------- campana
    const campana = document.getElementById('btnNotificaciones');
    if (campana) {
        const cont = campana.parentElement;
        campana.style.position = 'relative';
        const insignia = document.createElement('span');
        insignia.className = 'topbar-insignia d-none';
        campana.appendChild(insignia);

        const panel = crearDropdown(cont, 'topbar-dropdown-derecha');

        async function cargarAlertas() {
            try {
                const resp = await fetch(campana.dataset.url, { credentials: 'same-origin' });
                if (!resp.ok) return;
                const d = await resp.json();
                insignia.textContent = d.total > 99 ? '99+' : d.total;
                insignia.classList.toggle('d-none', d.total === 0);
                panel.innerHTML = '<div class="topbar-grupo">Pendientes</div>' + (d.items.length
                    ? d.items.map(i => `<a class="topbar-item d-flex gap-2" href="${esc(i.url)}">
                        <i class="bi ${i.icono}" style="color:${i.color}"></i>
                        <div><div class="fw-semibold">${esc(i.titulo)}</div>
                        <div class="small text-muted">${esc(i.detalle)}</div></div></a>`).join('')
                    : '<div class="p-3 small text-muted">No tienes pendientes</div>');
            } catch (e) { /* se reintenta en el siguiente ciclo */ }
        }

        campana.addEventListener('click', () => panel.classList.toggle('d-none'));
        cerrarAfuera(cont, panel);
        cargarAlertas();
        setInterval(cargarAlertas, 60000);
    }
});