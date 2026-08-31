document.addEventListener('DOMContentLoaded', function () {
    console.log('Vista Detalle Senderos inicializada.');

    const mapaDiv = document.getElementById('mapaGeometria');
    const wktInput = document.getElementById('geometriaWktInput');
    const btnLimpiar = document.getElementById('btnLimpiarDibujo');

    if (!mapaDiv || !wktInput) return;

    // Centro por defecto: Loja, Ecuador
    const centroDefault = [-3.9973, -79.2005];

    const mapa = L.map('mapaGeometria').setView(centroDefault, 13);

    const cartoKey = window.CARTO_API_KEY || '';
    const cartoTileUrl = cartoKey
        ? `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${cartoKey}`
        : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';   // fallback si falta la key

    L.tileLayer(cartoTileUrl, {
        attribution: '&copy; OpenStreetMap contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        maxZoom: 19,
        subdomains: 'abcd',
    }).addTo(mapa);

    // Recalcula el tamaño del contenedor (evita mapa en blanco dentro de columnas Bootstrap)
    setTimeout(function () {
        mapa.invalidateSize();
    }, 100);

    let puntos = [];       // array de [lat, lon] mientras se dibuja
    let polyline = null;   // capa activa dibujada en el mapa
    let dibujando = false;
    let sincronizandoDesdeMapa = false;   // evita loops entre mapa <-> textarea

    // --------------------------------------------------------
    // WKT -> array de puntos [lat, lon]
    // --------------------------------------------------------
    function parsearWkt(wkt) {
        const match = wkt.trim().match(/LINESTRING\s*\(([^)]+)\)/i);
        if (!match) return null;

        const coordenadasTexto = match[1].trim();
        if (!coordenadasTexto) return null;

        try {
            return coordenadasTexto.split(',').map(function (par) {
                const partes = par.trim().split(/\s+/).map(Number);
                const lon = partes[0];
                const lat = partes[1];
                if (isNaN(lon) || isNaN(lat)) throw new Error('coordenada inválida');
                return [lat, lon];   // Leaflet usa [lat, lon]
            });
        } catch (e) {
            return null;
        }
    }

    // --------------------------------------------------------
    // array de puntos [lat, lon] -> WKT
    // --------------------------------------------------------
    function puntosAWkt(listaPuntos) {
        if (!listaPuntos.length) return '';
        const coords = listaPuntos
            .map(function (p) { return p[1] + ' ' + p[0]; })   // lon lat
            .join(', ');
        return 'LINESTRING(' + coords + ')';
    }

    function dibujarEnMapa(listaPuntos) {
        if (polyline) {
            mapa.removeLayer(polyline);
            polyline = null;
        }
        if (listaPuntos && listaPuntos.length > 1) {
            polyline = L.polyline(listaPuntos, { color: '#3b82f6', weight: 4 }).addTo(mapa);
            mapa.fitBounds(polyline.getBounds(), { padding: [30, 30] });
        }
    }

    // --------------------------------------------------------
    // Carga inicial: si ya hay un WKT (modo edición), lo dibuja
    // --------------------------------------------------------
    const wktInicial = wktInput.value.trim();
    if (wktInicial) {
        const puntosIniciales = parsearWkt(wktInicial);
        if (puntosIniciales) {
            puntos = puntosIniciales;
            dibujarEnMapa(puntos);
        }
    }

    // --------------------------------------------------------
    // Dibujo manual con clics sobre el mapa
    // --------------------------------------------------------
    mapa.on('click', function (e) {
        puntos.push([e.latlng.lat, e.latlng.lng]);
        dibujarEnMapa(puntos);

        sincronizandoDesdeMapa = true;
        wktInput.value = puntosAWkt(puntos);
        sincronizandoDesdeMapa = false;
    });

    // --------------------------------------------------------
    // Escribir manualmente en el textarea -> redibuja el mapa
    // --------------------------------------------------------
    wktInput.addEventListener('input', function () {
        if (sincronizandoDesdeMapa) return;   // evita loop si el cambio vino del mapa

        const nuevosPuntos = parsearWkt(wktInput.value);
        if (nuevosPuntos) {
            puntos = nuevosPuntos;
            dibujarEnMapa(puntos);
        }
    });

    // --------------------------------------------------------
    // Botón "Limpiar dibujo"
    // --------------------------------------------------------
    if (btnLimpiar) {
        btnLimpiar.addEventListener('click', function () {
            puntos = [];
            dibujarEnMapa(puntos);
            wktInput.value = '';
        });
    }

    // --------------------------------------------------------
    // Selector de hora con reloj visual y AM/PM (Flatpickr)
    // --------------------------------------------------------
    if (typeof flatpickr !== 'undefined') {
        const configHora = {
            enableTime: true,
            noCalendar: true,
            dateFormat: 'H:i',     // valor real que se envía al servidor (24h, lo que Django espera)
            altInput: true,
            altFormat: 'h:i K',    // lo que ve el usuario (12h con AM/PM)
            time_24hr: false,
        };

        flatpickr('#horarioApertura', configHora);
        flatpickr('#horarioCierre', configHora);
    }
});