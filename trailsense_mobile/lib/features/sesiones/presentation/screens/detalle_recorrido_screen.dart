import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailsense_mobile/features/sesiones/presentation/controllers/sesiones_controller.dart';

import '../controllers/detalle_recorrido_controller.dart';

class DetalleRecorridoScreen extends GetView<DetalleRecorridoController> {
  const DetalleRecorridoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value || controller.sesion.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final sesion = controller.sesion.value!;
        final centro = sesion.traza.isNotEmpty ? sesion.traza.first : const LatLng(-3.9973, -79.2005);

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: centro, initialZoom: 14.0),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.trailsenseloja.trailsense_mobile'),
                if (sesion.traza.length > 1)
                  PolylineLayer(polylines: [Polyline(points: sesion.traza, strokeWidth: 4.0, color: const Color(0xFF3B82F6))]),
              ],
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    onPressed: () {
                      if (Get.isRegistered<SesionesController>()) {
                        Get.find<SesionesController>().cargarSesiones();
                      }
                      Get.back();
                    },
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sesion.senderoNombre ?? 'Recorrido libre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp)),
                        IconButton(icon: Icon(Icons.cancel, color: Colors.grey.shade400, size: 24.r), onPressed: () => Get.back()),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text('${sesion.iniciadoEn.day.toString().padLeft(2, '0')}/${sesion.iniciadoEn.month.toString().padLeft(2, '0')}/${sesion.iniciadoEn.year}',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                    SizedBox(height: 24.h),
                    Row(children: [
                      Expanded(child: _MetricItem(icon: Icons.straighten, text: '${sesion.distanciaKm.toStringAsFixed(2)} km', iconColor: Colors.redAccent)),
                      Expanded(child: _MetricItem(icon: Icons.timer_outlined, text: _formatearDuracion(sesion.duracionSegundos), iconColor: Colors.redAccent)),
                    ]),
                    SizedBox(height: 14.h),
                    Row(children: [
                      Expanded(child: _MetricItem(icon: Icons.speed, text: '${sesion.velocidadPromedioKmh.toStringAsFixed(1)} km/h', iconColor: const Color(0xFF3B82F6))),
                      Expanded(child: _MetricItem(icon: Icons.directions_walk, text: '${sesion.pasos} pasos', iconColor: Colors.amber.shade700)),
                    ]),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatearDuracion(int segundos) {
    final d = Duration(seconds: segundos);
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h $m' : '$m:$s';
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _MetricItem({required this.icon, required this.text, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18.r, color: iconColor),
      SizedBox(width: 8.w),
      Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
    ]);
  }
}