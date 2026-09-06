import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/detalle_sendero_controller.dart';

class DetalleSenderoScreen extends GetView<DetalleSenderoController> {
  const DetalleSenderoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value || controller.sendero.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final sendero = controller.sendero.value!;

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: sendero.puntoInicio,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trailsenseloja.trailsense_mobile',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: sendero.puntos, strokeWidth: 4.0, color: const Color(0xFF3B82F6)),
                  ],
                ),
              ],
            ),

            // IgnorePointer para que el mapa siga siendo interactivo
            IgnorePointer(
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${sendero.nombre} - ${sendero.canton}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13.sp),
                          ),
                          Icon(Icons.chevron_right, size: 18.r, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sendero.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.grey.shade400, size: 24.r),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // Botón "Crear Incidencia"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        onPressed: () => Get.toNamed('/crear-reporte', arguments: {
                          'senderoId': sendero.id,
                          'senderoNombre': sendero.nombre,
                        }),
                        child: Text('Crear Incidencia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      ),
                    ),
                    
                    SizedBox(height: 10.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MetricItem(icon: Icons.alt_route, text: 'Estado: ${sendero.estado}', iconColor: const Color(0xFF3B82F6)),
                              SizedBox(height: 8.h),
                              _MetricItem(icon: Icons.location_on_outlined, text: '${sendero.longitudKm} km de recorrido', iconColor: Colors.redAccent),
                              if (sendero.horarioApertura != null) ...[
                                SizedBox(height: 8.h),
                                _MetricItem(
                                  icon: Icons.timer_outlined,
                                  text: '${sendero.horarioApertura} - ${sendero.horarioCierre}',
                                  iconColor: Colors.redAccent,
                                ),
                              ],
                              SizedBox(height: 8.h),
                              _MetricItem(icon: Icons.terrain, text: 'Dificultad: ${sendero.dificultad}', iconColor: Colors.amber.shade700),
                            ],
                          ),
                        ),
                        if (sendero.imagenPortadaUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: Image.network(sendero.imagenPortadaUrl!, width: 140.w, height: 90.h, fit: BoxFit.cover),
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    Text('DESCRIPCIÓN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: const Color(0xFF474B66))),
                    SizedBox(height: 4.h),
                    Text(
                      sendero.descripcion.isNotEmpty ? sendero.descripcion : 'Sin descripción disponible.',
                      style: TextStyle(fontSize: 13.sp, color: const Color(0xFF474B66), height: 1.4),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _MetricItem({required this.icon, required this.text, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.r, color: iconColor),
        SizedBox(width: 8.w),
        Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp))),
      ],
    );
  }
}