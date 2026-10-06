import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/detalle_notificacion_controller.dart';
import '../../data/models/notificacion_model.dart';
import '../../../../core/constants/tipos_notificacion.dart';

class DetalleNotificacionScreen extends GetView<DetalleNotificacionController> {
  const DetalleNotificacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final n = controller.notificacion.value;
        if (controller.isLoading.value || n == null) return const Center(child: CircularProgressIndicator());

        final tipo = tipoNotificacionPorValor(n.tipo);
        final placeholder = Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Center(child: Icon(tipo.icono, size: 90.r, color: Colors.white70)),
        );

        return Column(
          children: [
            // Imagen (o placeholder): 60% de la altura de la pantalla
            SizedBox(
              height: 0.60.sh,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  n.imagenUrl != null
                      ? Image.network(n.imagenUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
                      : placeholder,
                  // Arriba a la izquierda: volver + tipo de notificación
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20), onPressed: () => Get.back()),
                            ),
                            SizedBox(width: 10.w),
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(20.r)),
                                child: Text(
                                  tipo.etiqueta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.black, fontSize: 15.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.tieneRelacionado) ...[
                      InkWell(
                        onTap: controller.abrirRelacionado,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              _miniaturaSendero(n, tipo),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.senderoNombre ?? 'Sendero', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                                    Text(n.reporteId != null ? 'Ver la incidencia reportada' : 'Ver detalle del sendero',
                                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                    // El título:
                    Text(n.titulo, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4.h),
                    // Fecha y mensaje:
                    Text(n.fechaTexto, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    SizedBox(height: 14.h),
                    Text(n.mensaje, style: TextStyle(fontSize: 15.sp, color: Colors.grey[700], height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // Cuadradito del acceso directo: foto del sendero, o el ícono si el sendero no tiene imagen
  Widget _miniaturaSendero(NotificacionModel n, TipoNotificacion tipo) {
    final icono = Container(
      width: 56.r, height: 56.r,
      color: tipo.color.withOpacity(0.12),
      child: Icon(n.reporteId != null ? Icons.campaign_outlined : Icons.terrain, color: tipo.color, size: 28.r),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 56.r, height: 56.r,
        child: n.senderoImagenUrl != null
            ? Image.network(n.senderoImagenUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => icono)
            : icono,
      ),
    );
  }
}