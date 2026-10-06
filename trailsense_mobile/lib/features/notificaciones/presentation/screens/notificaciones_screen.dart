import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/notificaciones_controller.dart';
import '../../data/models/notificacion_model.dart';
import '../../../../core/constants/tipos_notificacion.dart';

class NotificacionesScreen extends GetView<NotificacionesController> {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildCabecera(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.cargar(silencioso: true),
              child: Obx(() {
                if (controller.isLoading.value && controller.notificaciones.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = controller.filtradas;
                if (lista.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 120.h),
                      Center(child: Text('No hay notificaciones para mostrar.', style: TextStyle(color: Colors.grey[600], fontSize: 14.sp))),
                    ],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  itemCount: lista.length,
                  itemBuilder: (context, i) => _buildTarjeta(lista[i]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecera(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 8.w, 10.h),
      child: Obx(() {
        if (controller.mostrarBusqueda.value) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => controller.busqueda.value = v,
                  decoration: InputDecoration(
                    hintText: 'Buscar notificación...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: controller.alternarBusqueda),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avisos y alertas', style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                Text(
                  controller.noLeidas.value > 0 ? '${controller.noLeidas.value} sin leer' : 'Estás al día',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(icon: Icon(Icons.search, size: 26.r), onPressed: controller.alternarBusqueda),
                IconButton(
                  icon: Badge(isLabelVisible: controller.hayFiltros, smallSize: 8, child: Icon(Icons.more_horiz, size: 26.r)),
                  onPressed: _mostrarFiltros,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTarjeta(NotificacionModel n) {
    final tipo = tipoNotificacionPorValor(n.tipo);
    return GestureDetector(
      onTap: () => controller.abrirDetalle(n),
      child: Container(
        margin: EdgeInsets.only(top: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(n.origen == 'manual' ? Icons.notifications : tipo.icono, size: 44.r, color: n.origen == 'manual' ? const Color(0xFF0A9DFF) : tipo.color),
                if (!n.leida)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      width: 20.r, height: 20.r, alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xFFE11D1D), shape: BoxShape.circle),
                      child: Text('1', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16.sp, fontWeight: n.leida ? FontWeight.w500 : FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 2.h),
                  Text(n.mensaje, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(color: const Color(0xFF4C8DFF), borderRadius: BorderRadius.circular(6.r)),
              child: Text('Ver', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltros() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrar notificaciones', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo no leídas'),
                    value: controller.soloNoLeidas.value,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (v) => controller.soloNoLeidas.value = v,
                  )),
              SizedBox(height: 8.h),
              Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              Obx(() => Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: tiposNotificacion.map((t) {
                      final sel = controller.filtroTipo.value == t.valor;
                      return ChoiceChip(
                        label: Text(t.etiqueta),
                        selected: sel,
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: const Color(0xFFF0F2F5),
                        labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontSize: 12.sp),
                        onSelected: (_) => controller.filtroTipo.value = sel ? '' : t.valor,
                      );
                    }).toList(),
                  )),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: controller.limpiarFiltros, child: const Text('Limpiar'))),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                      child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}