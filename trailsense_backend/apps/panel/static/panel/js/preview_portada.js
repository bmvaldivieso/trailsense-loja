document.addEventListener('DOMContentLoaded', function () {
    const input = document.getElementById('inputImagenPortada');
    const circulo = document.getElementById('imgCirculo');
    const banner = document.getElementById('imgBanner');                 // solo existe al editar
    const contBanner = document.getElementById('heroBannerSendero');     // solo existe al editar
    if (!input || !circulo) return;

    // Estado original, para restaurar si el usuario cancela la selección
    const srcCirculoOriginal = circulo.getAttribute('src');
    const srcBannerOriginal = banner ? banner.getAttribute('src') : '';
    const bannerVisibleOriginal = contBanner ? !contBanner.classList.contains('d-none') : false;
    let urlTemporal = null;

    function liberar() {
        if (urlTemporal) { URL.revokeObjectURL(urlTemporal); urlTemporal = null; }
    }

    function restaurar() {
        circulo.src = srcCirculoOriginal;
        if (banner) {
            banner.src = srcBannerOriginal;
            contBanner.classList.toggle('d-none', !bannerVisibleOriginal);
        }
    }

    input.addEventListener('change', function () {
        const archivo = input.files && input.files[0];
        liberar();

        if (!archivo) { restaurar(); return; }                           // canceló el selector

        if (!archivo.type.startsWith('image/')) {
            alert('El archivo seleccionado no es una imagen.');
            input.value = '';
            restaurar();
            return;
        }

        urlTemporal = URL.createObjectURL(archivo);                      // vista previa instantánea, sin subir nada
        circulo.src = urlTemporal;
        if (banner) {
            banner.src = urlTemporal;
            contBanner.classList.remove('d-none');
        }
    });

    window.addEventListener('beforeunload', liberar);
});