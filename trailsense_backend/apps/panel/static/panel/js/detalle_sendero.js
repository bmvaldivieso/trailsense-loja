document.addEventListener('DOMContentLoaded', function () {
    console.log('Vista Detalle Senderos inicializada.');

    const mapaDiv = document.getElementById('mapaGeometria');
    const wktInput = document.getElementById('geometriaWktInput');
    const btnLimpiar = document.getElementById('btnLimpiarDibujo');
    const btnUbicacion = document.getElementById('btnFijarUbicacion');
    const selectEstado = document.querySelector('select[name="estado"]');

    if (!mapaDiv || !wktInput) return;

    const centroDefault = [-3.9973, -79.2005];

    const mapa = L.map('mapaGeometria').setView(centroDefault, 13);

    const cartoKey = window.CARTO_API_KEY || '';
    const cartoTileUrl = cartoKey
        ? `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${cartoKey}`
        : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

    L.tileLayer(cartoTileUrl, {
        attribution: '&copy; OpenStreetMap contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        maxZoom: 19,
        subdomains: 'abcd',
    }).addTo(mapa);

    setTimeout(function () { mapa.invalidateSize(); }, 100);

    let puntos = [];
    let polyline = null;
    let sincronizandoDesdeMapa = false;

    // --------------------------------------------------------
    // Color de la línea según el estado del sendero
    // --------------------------------------------------------
    const coloresPorEstado = {
        bueno: '#3b82f6',     // azul
        alerta: '#f59e0b',    // naranja
        critico: '#dc2626',   // rojo
    };

    function colorSegunEstado() {
        const valor = selectEstado ? selectEstado.value : 'bueno';
        return coloresPorEstado[valor] || coloresPorEstado.bueno;
    }

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
                return [lat, lon];
            });
        } catch (e) {
            return null;
        }
    }

    function puntosAWkt(listaPuntos) {
        if (!listaPuntos.length) return '';
        const coords = listaPuntos.map(function (p) { return p[1] + ' ' + p[0]; }).join(', ');
        return 'LINESTRING(' + coords + ')';
    }

    function dibujarEnMapa(listaPuntos) {
        if (polyline) {
            mapa.removeLayer(polyline);
            polyline = null;
        }
        if (listaPuntos && listaPuntos.length > 1) {
            polyline = L.polyline(listaPuntos, { color: colorSegunEstado(), weight: 4 }).addTo(mapa);
            mapa.fitBounds(polyline.getBounds(), { padding: [30, 30] });
        }
    }

    const wktInicial = wktInput.value.trim();
    if (wktInicial) {
        const puntosIniciales = parsearWkt(wktInicial);
        if (puntosIniciales) {
            puntos = puntosIniciales;
            dibujarEnMapa(puntos);
        }
    }

    mapa.on('click', function (e) {
        puntos.push([e.latlng.lat, e.latlng.lng]);
        dibujarEnMapa(puntos);
        sincronizandoDesdeMapa = true;
        wktInput.value = puntosAWkt(puntos);
        sincronizandoDesdeMapa = false;
    });

    wktInput.addEventListener('input', function () {
        if (sincronizandoDesdeMapa) return;
        const nuevosPuntos = parsearWkt(wktInput.value);
        if (nuevosPuntos) {
            puntos = nuevosPuntos;
            dibujarEnMapa(puntos);
        }
    });

    if (btnLimpiar) {
        btnLimpiar.addEventListener('click', function () {
            puntos = [];
            dibujarEnMapa(puntos);
            wktInput.value = '';
        });
    }

    // Si el admin cambia el estado en el <select>, la línea se recolorea al instante
    if (selectEstado) {
        selectEstado.addEventListener('change', function () {
            dibujarEnMapa(puntos);
        });
    }

    // --------------------------------------------------------
    // Botón "Fijar ubicación" — geolocalización del navegador
    // --------------------------------------------------------
    if (btnUbicacion) {
        btnUbicacion.addEventListener('click', function () {
            if (!navigator.geolocation) {
                mapa.setView(centroDefault, 13);
                return;
            }

            btnUbicacion.disabled = true;
            const textoOriginal = btnUbicacion.innerHTML;
            btnUbicacion.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Ubicando...';

            function intentarUbicacion(opciones, esReintento) {
                navigator.geolocation.getCurrentPosition(
                    function (posicion) {
                        mapa.setView([posicion.coords.latitude, posicion.coords.longitude], 15);
                        btnUbicacion.disabled = false;
                        btnUbicacion.innerHTML = textoOriginal;
                    },
                    function (error) {
                        // Si fue timeout en el primer intento, reintenta una vez con menos exigencia
                        if (error.code === 3 && !esReintento) {
                            intentarUbicacion({ enableHighAccuracy: false, timeout: 15000 }, true);
                            return;
                        }

                        mapa.setView(centroDefault, 13);
                        btnUbicacion.disabled = false;
                        btnUbicacion.innerHTML = textoOriginal;
                    },
                    opciones
                );
            }

            intentarUbicacion({ enableHighAccuracy: true, timeout: 8000, maximumAge: 0 }, false);
        });
    }

    // --------------------------------------------------------
    // Selector de cantones de Loja — respaldo cuando el GPS falla
    // --------------------------------------------------------
    const cantonesLoja = [
        { nombre: 'Loja',         lat: -3.9931, lon: -79.2042 }, // Ciudad de Loja
        { nombre: 'Catamayo',     lat: -3.9841, lon: -79.3515 }, // Centro de Catamayo
        { nombre: 'Calvas',       lat: -4.3249, lon: -79.5539 }, // Cariamanga (Cabecera)
        { nombre: 'Célica',       lat: -4.1031, lon: -79.9548 }, // Celica ciudad
        { nombre: 'Chaguarpamba', lat: -3.8906, lon: -79.6444 }, // Chaguarpamba ciudad
        { nombre: 'Espíndola',    lat: -4.5878, lon: -79.4328 }, // Amaluza (Cabecera)
        { nombre: 'Gonzanamá',    lat: -4.2312, lon: -79.4344 }, // Gonzanamá ciudad
        { nombre: 'Macará',       lat: -4.3820, lon: -79.9439 }, // Macará ciudad
        { nombre: 'Olmedo',       lat: -3.9351, lon: -79.6469 }, // Parque Central de Olmedo, Loja
        { nombre: 'Paltas',       lat: -4.0411, lon: -79.6540 }, // Catacocha (Cabecera)
        { nombre: 'Pindal',       lat: -4.1161, lon: -80.1114 }, // Pindal ciudad
        { nombre: 'Puyango',      lat: -4.0195, lon: -80.0094 }, // Alamor (Cabecera)
        { nombre: 'Quilanga',     lat: -4.2989, lon: -79.4042 }, // Quilanga ciudad
        { nombre: 'Saraguro',     lat: -3.6214, lon: -79.2381 }, // Saraguro ciudad
        { nombre: 'Sozoranga',    lat: -4.3292, lon: -79.7914 }, // Sozoranga ciudad
        { nombre: 'Zapotillo',    lat: -4.3831, lon: -80.2436 }  // Zapotillo ciudad
    ];

    const listaCantones = document.getElementById('listaCantones');

    if (listaCantones) {
        cantonesLoja.forEach(function (canton) {
            const item = document.createElement('li');
            const link = document.createElement('a');
            link.className = 'dropdown-item';
            link.href = '#';
            link.textContent = canton.nombre;
            link.addEventListener('click', function (e) {
                e.preventDefault();
                mapa.setView([canton.lat, canton.lon], 13);
            });
            item.appendChild(link);
            listaCantones.appendChild(item);
        });
    }

    if (typeof flatpickr !== 'undefined') {
        const configHora = { enableTime: true, noCalendar: true, dateFormat: 'H:i', altInput: true, altFormat: 'h:i K', time_24hr: false };
        flatpickr('#horarioApertura', configHora);
        flatpickr('#horarioCierre', configHora);
    }
});