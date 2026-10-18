// Activa el desplazamiento solo en los .marquee cuyo texto no cabe en su contenedor.
window.activarMarquee = function (raiz) {
    (raiz || document).querySelectorAll('.marquee').forEach(function (cont) {
        const texto = cont.querySelector('.marquee-texto');
        if (!texto) return;
        cont.classList.remove('marquee-activo');
        const exceso = texto.scrollWidth - cont.clientWidth;
        if (exceso > 4) {
            cont.style.setProperty('--desp', '-' + (exceso + 8) + 'px');
            cont.style.setProperty('--dur', Math.max(4, (exceso + 8) / 30) + 's');   // ~30 px/s
            cont.classList.add('marquee-activo');
        }
    });
};

let temporizadorMarquee = null;
window.addEventListener('resize', function () {
    clearTimeout(temporizadorMarquee);
    temporizadorMarquee = setTimeout(() => window.activarMarquee(), 200);
});
document.addEventListener('DOMContentLoaded', () => window.activarMarquee());
if (document.fonts && document.fonts.ready) document.fonts.ready.then(() => window.activarMarquee());