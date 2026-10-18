document.addEventListener('DOMContentLoaded', function () {
    const wkt = document.getElementById('geometriaWktInput');
    const btnLimpiar = document.getElementById('btnLimpiarDibujo');
    const direccion = document.getElementById('direccion');
    const input = document.getElementById('inputTraza');
    const btnSubir = document.getElementById('btnSubirTraza');
    const btnQuitar = document.getElementById('btnQuitarTraza');
    const fila = document.getElementById('filaTraza');
    const info = document.getElementById('infoTraza');
    const btnCalc = document.getElementById('btnCalcularDireccion');
    const ayuda = document.getElementById('ayudaDireccion');
    if (!wkt || !input) return;

    let direccionAutomatica = false;

    const csrf = () => {
        const campo = document.querySelector('[name=csrfmiddlewaretoken]');
        return campo ? campo.value : ((document.cookie.match(/csrftoken=([^;]+)/) || [])[1] || '');
    };
    const avisar = (txt, error) => {
        fila.classList.remove('d-none'); fila.classList.add('d-flex');
        info.textContent = txt;
        info.className = error ? 'text-danger' : 'text-muted';
    };
    const ocultarFila = () => { fila.classList.add('d-none'); fila.classList.remove('d-flex'); };

    btnSubir.addEventListener('click', () => input.click());

    input.addEventListener('change', async function () {
        const archivo = input.files[0];
        if (!archivo) return;

        btnSubir.disabled = true;
        btnQuitar.classList.add('d-none');
        avisar('Procesando ' + archivo.name + '...');
        const datos = new FormData();
        datos.append('archivo', archivo);

        try {
            const resp = await fetch(window.URL_PROCESAR_TRAZA, {
                method: 'POST', credentials: 'same-origin',
                headers: { 'X-CSRFToken': csrf() }, body: datos,
            });
            const r = await resp.json();
            if (!resp.ok) { input.value = ''; avisar(r.message || 'No se pudo procesar el archivo.', true); return; }

            // Escribe el WKT: tu sincronización WKT -> mapa lo dibuja
            wkt.value = r.wkt;
            wkt.dispatchEvent(new Event('input', { bubbles: true }));
            wkt.dispatchEvent(new Event('change', { bubbles: true }));

            avisar(`${archivo.name}: ${r.puntos_originales.toLocaleString('es')} → ${r.puntos_resultantes} puntos · ${r.longitud_km} km`);
            btnQuitar.classList.remove('d-none');
            if (!direccion.value.trim()) calcularDireccion();
        } catch (e) {
            input.value = '';
            avisar('Error de conexión al procesar el archivo.', true);
        } finally {
            btnSubir.disabled = false;
        }
    });

    btnQuitar.addEventListener('click', function () {
        input.value = '';
        if (btnLimpiar) btnLimpiar.click();      // borra lo dibujado en el mapa
        wkt.value = '';
        if (direccionAutomatica) { direccion.value = ''; direccionAutomatica = false; }
        ocultarFila();
    });

    async function calcularDireccion() {
        if (!wkt.value.trim()) { ayuda.textContent = 'Dibuja o carga primero el trazado del sendero.'; return; }
        btnCalc.disabled = true;
        ayuda.textContent = 'Buscando las calles del trazado (puede tardar unos segundos)...';
        try {
            const resp = await fetch(window.URL_DIRECCION_SUGERIDA, {
                method: 'POST', credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json', 'X-CSRFToken': csrf() },
                body: JSON.stringify({ wkt: wkt.value }),
            });
            const r = await resp.json();
            if (!resp.ok) { ayuda.textContent = r.message || 'No se pudo obtener la dirección.'; return; }
            if (r.texto) {
                direccion.value = r.texto;
                direccionAutomatica = true;
                ayuda.textContent = 'Dirección calculada con el trazado. Puedes editarla.';
            } else {
                ayuda.textContent = r.aviso;
            }
        } catch (e) {
            ayuda.textContent = 'Sin conexión para consultar la dirección. Puedes escribirla manualmente.';
        } finally {
            btnCalc.disabled = false;
        }
    }

    btnCalc.addEventListener('click', calcularDireccion);
    direccion.addEventListener('input', () => { direccionAutomatica = false; });   // lo escrito a mano se respeta
});