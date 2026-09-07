import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/reportes_controller.dart';
import '../../data/models/reporte_model.dart';
import '../../../../core/constants/categorias_reporte.dart';

import '../../../../core/widgets/marquee_text.dart';

class ReportesScreen extends GetView<ReportesController> {
  const ReportesScreen({super.key});

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
                  polylines: controller.senderosParaDibujar.map((s) {
                    return Polyline(points: s.puntos, strokeWidth: 3.0, color: Colors.blue);
                  }).toList(),
                ),
                MarkerLayer(
                  markers: controller.reportesFiltrados.map((r) {
                    final cat = categoriaPorValor(r.categoria);
                    return Marker(
                      point: LatLng(r.lat, r.lon),
                      width: 32.w,
                      height: 32.h,
                      child: Icon(cat.icono, color: cat.color, size: 30.r),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Botón "Ver mis reportes" — arriba a la derecha
          Positioned(
            top: 16.h,
            right: 16.w,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed('/mis-reportes'),
                icon: const Icon(Icons.person, size: 16, color: Color(0xFF3B82F6)),
                label: Text('Ver mis Reportes', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF3B82F6))),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 3),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: 0.42.sh),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  const Row(
                    children: [
                      Text('REPORTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  TextField(  
                    onChanged: controller.actualizarBusqueda,
                    decoration: InputDecoration(
                      hintText: 'Buscar reporte...',
                      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r), borderSide: BorderSide.none),
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                      final lista = controller.reportesFiltrados;
                      if (lista.isEmpty) return const Center(child: Text('No hay reportes registrados aún.'));
                      return ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => Divider(height: 1.h, color: Colors.grey[200]),
                        itemBuilder: (context, index) => _buildReporteCard(lista[index]),
                      );
                    }),
                  ),

                  Divider(height: 1.h),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _mostrarFiltros(context),
                          child: const Row(children: [Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)), Icon(Icons.chevron_right, size: 18)]),
                        ),
                        Obx(() => controller.filtroCategoria.value.isNotEmpty
                            ? TextButton(onPressed: controller.limpiarFiltros, child: const Text('Limpiar'))
                            : const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporteCard(ReporteModel reporte) {
    final cat = categoriaPorValor(reporte.categoria);
    return InkWell(
      onTap: () => controller.seleccionarReporte(reporte),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: cat.color.withOpacity(0.15), child: Icon(cat.icono, color: cat.color, size: 20.r)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.etiqueta, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  Text(reporte.senderoNombre, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                  SizedBox(height: 2.h),
                  MarqueeText(                                   // NUEVO
                    text: reporte.descripcion,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    height: 14.h,
                    umbral: 30,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black54),
              onPressed: () => Get.toNamed('/detalle-reporte', arguments: reporte.id),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltros(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrar por categoría', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: categoriasReporte.map((c) {
                return Obx(() {
                  final seleccionado = controller.filtroCategoria.value == c.valor;
                  return ChoiceChip(
                    label: Text(c.etiqueta),
                    selected: seleccionado,
                    selectedColor: const Color(0xFF3B82F6),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: seleccionado ? Colors.white : Colors.black87),
                    onSelected: (_) {
                      controller.aplicarFiltro(c.valor);
                      Get.back();
                    },
                  );
                });
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}