import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/nuevo_recorrido_controller.dart';

class NuevoRecorridoScreen extends GetView<NuevoRecorridoController> {
  const NuevoRecorridoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (controller.estado.value == 'inicial' || controller.estado.value == 'finalizada') {
              Get.back();
            } else {
              Get.snackbar('Recorrido en curso', 'Detén el recorrido antes de salir.');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo_trailsense.png',
                    width: 50.w,
                    height: 50.h,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 16.h),
                Text('Nuevo Recorrido', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                SizedBox(height: 8.h),
                Obx(() => _buildEstadoBadge(controller.estado.value)),
                // Nombre del sendero detectado, si lo hay
                Obx(() {
                  final nombre = controller.sesion.value?.senderoNombre;
                  if (nombre == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text('Recorriendo: $nombre', style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
                  );
                }),
                SizedBox(height: 20.h),
                Container(
                  width: 90.w,
                  height: 90.h,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEBF3FE),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Image.asset(
                        'assets/images/ruta.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Obx(
                  () => ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatRow('Distancia', '${controller.distanciaKm.value.toStringAsFixed(2)} km'),
                      _buildStatRow('Duración', controller.duracionFormateada),
                      _buildStatRow('Velocidad promedio', '${controller.velocidadPromedioKmh.value.toStringAsFixed(1)} km/h'),
                      _buildStatRow('Pasos', '${controller.pasos.value}'),
                    ],
                  ),
                ),
                Obx(() => _buildControles()),
                SizedBox(height: 140.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    final colores = {'inicial': Colors.grey, 'grabando': const Color(0xFF138A72), 'pausada': Colors.orange, 'finalizada': const Color(0xFF3B82F6)};
    final etiquetas = {'inicial': 'Listo para iniciar', 'grabando': 'Grabando', 'pausada': 'Pausado', 'finalizada': 'Finalizado'};

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(color: colores[estado] ?? Colors.grey, borderRadius: BorderRadius.circular(4.r)),
      child: Text(etiquetas[estado] ?? estado, style: TextStyle(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2D3142))),
          Text(value, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
        ],
      ),
    );
  }

  Widget _buildControles() {
    switch (controller.estado.value) {
      case 'inicial':
        return controller.requisitosListos
            ? _BotonObturador(detener: false, onTap: controller.iniciarRecorrido)
            : const _PanelRequisitos();

      case 'grabando':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BotonSecundario(icono: Icons.pause_rounded, onTap: controller.pausarRecorrido),
            SizedBox(width: 28.w),
            _BotonObturador(detener: true, onTap: controller.finalizarRecorrido),
          ],
        );

      case 'pausada':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BotonSecundario(icono: Icons.play_arrow_rounded, onTap: controller.reanudarRecorrido),
            SizedBox(width: 28.w),
            _BotonObturador(detener: true, onTap: controller.finalizarRecorrido),
          ],
        );

      default:
        return SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
            child: Text('Volver', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        );
    }
  }
}


/// Botón principal estilo "obturador de cámara": aro blanco con una
/// forma roja interior que cambia entre círculo (iniciar) y cuadrado
/// redondeado (detener), con animación de escala al presionar.
class _BotonObturador extends StatefulWidget {
  final bool detener;
  final VoidCallback onTap;

  const _BotonObturador({required this.detener, required this.onTap});

  @override
  State<_BotonObturador> createState() => _BotonObturadorState();
}

class _BotonObturadorState extends State<_BotonObturador> with SingleTickerProviderStateMixin {
  late final AnimationController _controllerAnim;
  late final Animation<double> _escala;

  @override
  void initState() {
    super.initState();
    _controllerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _escala = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controllerAnim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controllerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controllerAnim.forward(),
      onTapUp: (_) {
        _controllerAnim.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controllerAnim.reverse(),
      child: AnimatedBuilder(
        animation: _escala,
        builder: (context, child) => Transform.scale(scale: _escala.value, child: child),
        child: Container(
          width: 76.w,
          height: 76.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.06),
            border: Border.all(color: Colors.white, width: 4.w),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: widget.detener ? 30.w : 54.w,
              height: widget.detener ? 30.h : 54.h,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(widget.detener ? 8.r : 27.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario circular (pausar / reanudar), con aro claro y
/// transición animada entre íconos.
class _BotonSecundario extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _BotonSecundario({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 56.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEBF3FE),
          border: Border.all(color: const Color(0xFFD0E2FF), width: 2.w),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(icono, key: ValueKey(icono), color: const Color(0xFF2D3142), size: 26.sp),
          ),
        ),
      ),
    );
  }
}


/// Lista de requisitos obligatorios. Ocupa el lugar del botón de inicio mientras falte alguno.
class _PanelRequisitos extends GetView<NuevoRecorridoController> {
  const _PanelRequisitos();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_amber_rounded, color: const Color(0xFFF97316), size: 22.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('Antes de iniciar el recorrido',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                ),
              ]),
              SizedBox(height: 4.h),
              Text(
                'Estos requisitos son obligatorios. El botón de inicio aparecerá cuando todo esté listo.',
                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
              ),
              SizedBox(height: 12.h),
              _FilaRequisito(
                ok: controller.gpsActivo.value,
                titulo: 'GPS del teléfono',
                detalle: 'Activa el GPS: es obligatorio para grabar un recorrido.',
                accion: 'Activar GPS',
                onTap: controller.resolverGps,
                habilitado: !controller.resolviendo.value,
              ),
              _FilaRequisito(
                ok: controller.permisoUbicacion.value,
                titulo: 'Permiso de ubicación',
                detalle: controller.ubicacionBloqueada.value
                    ? 'Fue negado antes. Actívalo en Ajustes > Permisos > Ubicación.'
                    : 'Permite que TrailSense use tu ubicación mientras usas la app.',
                accion: controller.ubicacionBloqueada.value ? 'Abrir ajustes' : 'Permitir',
                onTap: controller.resolverUbicacion,
                habilitado: !controller.resolviendo.value,
              ),
              if (controller.permisoUbicacion.value)
                _FilaRequisito(
                  ok: controller.ubicacionPrecisa.value,
                  titulo: 'Ubicación precisa',
                  detalle: 'Elige "Ubicación precisa": la aproximada desvía el recorrido cientos de metros.',
                  accion: 'Activar',
                  onTap: controller.resolverPrecision,
                  habilitado: !controller.resolviendo.value,
                ),
              _FilaRequisito(
                ok: controller.permisoActividad.value,
                titulo: 'Actividad física',
                detalle: controller.actividadBloqueada.value
                    ? 'Fue negado antes. Actívalo en Ajustes > Permisos > Actividad física.'
                    : 'Necesario para contar tus pasos durante el recorrido.',
                accion: controller.actividadBloqueada.value ? 'Abrir ajustes' : 'Permitir',
                onTap: controller.resolverActividad,
                habilitado: !controller.resolviendo.value,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.comprobando.value || controller.resolviendo.value
                      ? null
                      : controller.comprobarManualmente,
                  icon: controller.comprobando.value
                      ? SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                  label: Text(controller.comprobando.value ? 'Comprobando…' : 'Volver a comprobar'),
                ),
              ),
            ],
          ),
        ));
  }
}

class _FilaRequisito extends StatelessWidget {
  final bool ok;
  final String titulo;
  final String detalle;
  final String accion;
  final Future<void> Function() onTap;
  final bool habilitado;

  const _FilaRequisito({
    required this.ok,
    required this.titulo,
    required this.detalle,
    required this.accion,
    required this.onTap,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? const Color(0xFF138A72) : const Color(0xFFDC2626),
            size: 22.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2D3142))),
                if (!ok)
                  Text(detalle, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              ],
            ),
          ),
          if (!ok)
            TextButton(
              onPressed: habilitado ? onTap : null,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(accion, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}