import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../../senderos/presentation/widgets/filtros_senderos_sheet.dart';
import '../../../senderos/data/models/sendero_model.dart';
import '../../../reportes/data/models/reporte_model.dart';
import '../../../../core/constants/categorias_reporte.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Senderos', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('Loja', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.black87, size: 26.r),
                      onPressed: controller.alternarBusqueda,
                    ),
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: Colors.black87, size: 26.r),
                      onPressed: () => mostrarFiltrosSenderos(context, controller.senderosController, mostrarBotonLimpiar: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12.h),
          // Buscador, reutiliza SenderosController.actualizarBusqueda
          Obx(() {
            if (!controller.mostrarBusqueda.value) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                autofocus: true,
                onChanged: controller.senderosController.actualizarBusqueda,
                decoration: InputDecoration(
                  hintText: 'Buscar sendero por nombre...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r), borderSide: BorderSide.none),
                ),
              ),
            );
          }),

          SizedBox(height: 16.h),

          // 2. Carrusel (reutiliza SenderosController — ya viene ordenado por fecha desde el backend)
          Obx(() {
            final lista = controller.senderosController.senderosFiltrados.take(10).toList();

            if (controller.senderosController.isLoading.value) {
              return SizedBox(height: 250.h, child: const Center(child: CircularProgressIndicator()));
            }
            if (lista.isEmpty) {
              return SizedBox(height: 80.h, child: Center(child: Text('No hay senderos disponibles', style: TextStyle(color: Colors.grey[600]))));
            }
            return SizedBox(
              height: 250.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: lista.length,
                itemBuilder: (context, index) => _buildSenderoCard(lista[index]),
              ),
            );
          }),

          Divider(thickness: 1.h, color: const Color(0xFFEEEEEE)),
          SizedBox(height: 12.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('INCIDENCIAS', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black87)),
                TextButton(
                  onPressed: () => Get.find<MainController>().changePage(3),   // Va a la pestaña Reportes
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF80B3FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  ),
                  child: Text('Ver todo', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // 4. Lista (reutiliza ReportesController — todos los reportes, no solo del usuario)
          Obx(() {
            final lista = controller.reportesController.reportes;

            if (controller.reportesController.isLoading.value) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()));
            }
            if (lista.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text('No hay incidencias registradas', style: TextStyle(color: Colors.grey[600])),
              );
            }
            return SizedBox(
              height: 280.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: lista.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (context, index) => _buildIncidenciaTile(lista[index]),
              ),
            );
          }),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSenderoCard(SenderoModel sendero) {
    return GestureDetector(
      onTap: () => Get.toNamed('/detalle-sendero', arguments: sendero.id),
      child: Container(
        width: 170.w,
        margin: EdgeInsets.only(right: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                height: 140.h,
                width: 170.w,
                color: Colors.grey[300],
                child: sendero.imagenPortadaUrl != null
                    ? Image.network(sendero.imagenPortadaUrl!, fit: BoxFit.cover)
                    : Icon(Icons.image, color: Colors.grey, size: 50.r),
              ),
            ),
            SizedBox(height: 10.h),
            Text(sendero.nombre, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 4.h),
            Text(sendero.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenciaTile(ReporteModel reporte) {
    final cat = categoriaPorValor(reporte.categoria);
    return GestureDetector(
      onTap: () => Get.toNamed('/detalle-reporte', arguments: reporte.id),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              height: 65.h,
              width: 65.w,
              color: cat.color.withOpacity(0.15),
              child: reporte.fotoPortadaUrl != null
                  ? Image.network(reporte.fotoPortadaUrl!, fit: BoxFit.cover)
                  : Icon(cat.icono, color: cat.color, size: 24.r),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.etiqueta, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4.h),
                Text(reporte.senderoNombre, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.black87, size: 24.r),
        ],
      ),
    );
  }
}