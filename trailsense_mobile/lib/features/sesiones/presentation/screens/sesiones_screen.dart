import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sesiones_controller.dart';
import '../../data/models/sesion_model.dart';

class SesionesScreen extends GetView<SesionesController> {
  const SesionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(initialCenter: controller.centroInicial, initialZoom: 13.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trailsenseloja.trailsense_mobile',
                ),
                PolylineLayer(
                  polylines: <Polyline>[
                    if (controller.sesionSeleccionada.value != null &&
                        controller.sesionSeleccionada.value!.traza.length > 1)
                      Polyline(
                        points: controller.sesionSeleccionada.value!.traza,
                        strokeWidth: 4.0,
                        color: const Color(0xFF3B82F6),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: 0.40.sh),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30.r), topRight: Radius.circular(30.r)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 5.h,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text('RECORRIDOS',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: const Color(0xFF2D3142))),
                  ),
                  SizedBox(height: 8.h),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h), child: _buildNuevoCard()),
                  Divider(height: 1.h, thickness: 1, color: Colors.grey[200]),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                      if (controller.sesiones.isEmpty) return const Center(child: Text('Aún no tienes recorridos registrados.'));
                      return ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        itemCount: controller.sesiones.length,
                        separatorBuilder: (_, __) => Divider(height: 1.h, color: Colors.grey[200]),
                        itemBuilder: (context, index) => _buildRecorridoCard(controller.sesiones[index]),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNuevoCard() {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12.r)),
          child: Icon(Icons.route, color: const Color(0xFF38B6FF), size: 28.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Text('Nuevo recorrido', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)))),
        ElevatedButton(
          onPressed: () => Get.toNamed('/nuevo-recorrido'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4C84F6),
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: Text('Iniciar Nuevo', style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRecorridoCard(SesionModel sesion) {
    final fecha = '${sesion.iniciadoEn.day.toString().padLeft(2, '0')}/${sesion.iniciadoEn.month.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => controller.seleccionarSesion(sesion),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12.r)),
              child: Icon(Icons.hiking, color: const Color(0xFF38B6FF), size: 26.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sesion.nombreMostrable,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
                  ),
                  SizedBox(height: 2.h),
                  Text(fecha, style: TextStyle(fontSize: 12.sp, color: Colors.grey[500])),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      _buildMetricItem('Distancia', '${sesion.distanciaKm.toStringAsFixed(2)} km'),
                      SizedBox(width: 16.w),
                      _buildMetricItem('Duración', _formatearDuracion(sesion.duracionSegundos)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black54),
              onPressed: () => Get.toNamed('/detalle-recorrido', arguments: sesion.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey[500])),
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
      ],
    );
  }

  String _formatearDuracion(int segundos) {
    final d = Duration(seconds: segundos);
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}