import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/senderos_controller.dart';
import '../../data/models/sendero_model.dart';

class SenderosScreen extends GetView<SenderosController> {
  const SenderosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: controller.centroInicial,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trailsenseloja.trailsense_mobile',
                ),
                PolylineLayer(
                  polylines: controller.senderos.map((s) {
                    final esSeleccionado = controller.senderoSeleccionado.value?.id == s.id;
                    return Polyline(
                      points: s.puntos,
                      strokeWidth: esSeleccionado ? 5.0 : 3.0,
                      color: esSeleccionado ? const Color(0xFF3B82F6) : Colors.grey.shade500,
                    );
                  }).toList(),
                ),
                // Marcadores tipo pin
                MarkerLayer(
                  markers: [
                    // 1. Marcadores de los senderos (puntos de inicio y fin)
                    ...controller.senderos.expand((s) {
                      if (s.puntos.isEmpty) return <Marker>[];
                      return [
                        Marker(
                          point: s.puntos.first,
                          width: 34.w,
                          height: 34.h,
                          child: const Icon(Icons.location_on, color: Color(0xFF1E293B), size: 34),
                        ),
                        Marker(
                          point: s.puntos.last,
                          width: 34.w,
                          height: 34.h,
                          child: const Icon(Icons.location_on, color: Color(0xFF1E293B), size: 34),
                        ),
                      ];
                    }),

                    // 2. Marcador de la ubicación actual del dispositivo (si está disponible)
                    if (controller.ubicacionActual.value != null)
                      Marker(
                        point: controller.ubicacionActual.value!,
                        width: 24.w,
                        height: 24.h,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),

          // Botón de "mi ubicación", conectado
          Positioned(
            right: 16.w,
            bottom: 300.h,
            child: FloatingActionButton.small(
              heroTag: 'gps_senderos',
              backgroundColor: Colors.white,
              onPressed: controller.centrarEnMiUbicacion,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
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
                      Text('SENDEROS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Buscador por nombre
                  TextField(
                    onChanged: controller.actualizarBusqueda,
                    decoration: InputDecoration(
                      hintText: 'Buscar sendero por nombre...',
                      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final lista = controller.senderosFiltrados;

                    if (lista.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No hay senderos disponibles')),
                      );
                    }

                    return SizedBox(
                      height: 180.h,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          final sendero = lista[index];
                          final activo = controller.senderoSeleccionado.value?.id == sendero.id;
                          return _buildTrailCard(context, sendero, activo);
                        },
                      ),
                    );
                  }),

                  const Divider(height: 1),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _mostrarFiltros(context),
                          child: const Row(
                            children: [
                              Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
                              Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                        Obx(
                          () => (controller.filtroDificultad.value.isNotEmpty ||
                                  controller.filtroEstado.value.isNotEmpty)
                              ? TextButton(
                                  onPressed: controller.limpiarFiltros,
                                  child: const Text(
                                    'Limpiar',
                                    style: TextStyle(color: Color(0xFF3B82F6)),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
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

  Widget _buildTrailCard(BuildContext context, SenderoModel sendero, bool activo) {
    return GestureDetector(
      onTap: () => controller.seleccionarSendero(sendero),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: activo ? Border.all(color: const Color(0xFF3B82F6), width: 1.2) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sendero.nombre.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  Text(sendero.canton, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text('${sendero.longitudKm} km',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      SizedBox(width: 12.w),
                      Icon(Icons.terrain, size: 16.r, color: const Color(0xFF3B82F6)),
                      Text(' ${sendero.dificultad}', style: TextStyle(fontSize: 12.sp)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black54),
              onPressed: () => Get.toNamed('/detalle-sendero', arguments: sendero.id),
            ),
            if (sendero.imagenPortadaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(sendero.imagenPortadaUrl!, width: 110.w, height: 65.h, fit: BoxFit.cover),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrar senderos', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            Text('Dificultad', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: ['baja', 'media', 'alta'].map((d) {
                final seleccionado = controller.filtroDificultad.value == d;
                return ChoiceChip(
                  label: Text(d),
                  selected: seleccionado,
                  selectedColor: const Color(0xFF3B82F6),
                  labelStyle: TextStyle(color: seleccionado ? Colors.white : Colors.black87),
                  backgroundColor: const Color(0xFFF0F2F5),
                  onSelected: (_) {
                    controller.aplicarFiltro(dificultad: d);
                    Get.back();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
            Text('Estado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: ['bueno', 'alerta', 'critico'].map((e) {
                final seleccionado = controller.filtroEstado.value == e;
                return ChoiceChip(
                  label: Text(e),
                  selected: seleccionado,
                  selectedColor: const Color(0xFF3B82F6),
                  labelStyle: TextStyle(color: seleccionado ? Colors.white : Colors.black87),
                  backgroundColor: const Color(0xFFF0F2F5),
                  onSelected: (_) {
                    controller.aplicarFiltro(estado: e);
                    Get.back();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}