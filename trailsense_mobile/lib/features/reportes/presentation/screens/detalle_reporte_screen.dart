import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/detalle_reporte_controller.dart';
import '../../../../core/constants/categorias_reporte.dart';

import '../../../../core/widgets/marquee_text.dart';

class DetalleReporteScreen extends GetView<DetalleReporteController> {
  const DetalleReporteScreen({super.key});

  void _abrirImagenCompleta(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, __) => FadeTransition(
          opacity: animation,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value || controller.reporte.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final reporte = controller.reporte.value!;
        final cat = categoriaPorValor(reporte.categoria);
        final ubicacion = LatLng(reporte.lat, reporte.lon);

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: ubicacion, initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trailsenseloja.trailsense_mobile',
                ),
                if (controller.senderoAsociado.value != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: controller.senderoAsociado.value!.puntos, strokeWidth: 4.0, color: const Color(0xFF3B82F6)),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ubicacion,
                      width: 40.w,
                      height: 40.h,
                      child: Icon(cat.icono, color: cat.color, size: 36),
                    ),
                  ],
                ),
              ],
            ),

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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icono, size: 16.r, color: cat.color),
                          SizedBox(width: 6.w),
                          Text(reporte.senderoNombre, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13.sp)),
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
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: 0.55.sh),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                      SizedBox(height: 12.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(cat.etiqueta, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp))),
                          IconButton(icon: Icon(Icons.cancel, color: Colors.grey.shade400, size: 24.r), onPressed: () => Get.back()),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(reporte.senderoNombre, style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
                      SizedBox(height: 16.h),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MetricItem(icon: cat.icono, text: cat.etiqueta, iconColor: cat.color),
                                SizedBox(height: 8.h),
                                _MetricItem(
                                  icon: Icons.calendar_today_outlined,
                                  text: '${reporte.fechaCreacion.day}/${reporte.fechaCreacion.month}/${reporte.fechaCreacion.year}',
                                  iconColor: Colors.redAccent,
                                ),
                                SizedBox(height: 8.h),
                                _MetricItem(
                                  icon: reporte.validado ? Icons.verified : Icons.hourglass_empty,
                                  text: reporte.validado ? 'Validado' : 'Pendiente de validación',
                                  iconColor: reporte.validado ? Colors.green.shade600 : Colors.amber.shade700,
                                ),
                              ],
                            ),
                          ),
                        // Imagen principal
                        if (reporte.fotos.isNotEmpty)
                          GestureDetector(
                            onTap: () => _abrirImagenCompleta(context, reporte.fotos.first.url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.network(reporte.fotos.first.url, width: 140.w, height: 90.h, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      Text('DESCRIPCIÓN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: const Color(0xFF474B66))),
                      SizedBox(height: 4.h),
                      Text(reporte.descripcion, style: TextStyle(fontSize: 13.sp, color: const Color(0xFF474B66), height: 1.4)),

                      if (reporte.fotos.length > 1) ...[
                        SizedBox(height: 16.h),
                        Text('MÁS FOTOS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: const Color(0xFF474B66))),
                        SizedBox(height: 8.h),
                        SizedBox(
                          height: 80.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: reporte.fotos.length - 1,
                            separatorBuilder: (_, __) => SizedBox(width: 8.w),
                            // Tira de fotos adicionales
                            itemBuilder: (context, index) => GestureDetector(
                              onTap: () => _abrirImagenCompleta(context, reporte.fotos[index + 1].url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.network(reporte.fotos[index + 1].url, width: 80.w, height: 80.h, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 12.h),
                    ],
                  ),
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
        Expanded(
          child: MarqueeText(
            text: text,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
            height: 18.h,
          ),
        ),
      ],
    );
  }
}