import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/mis_reportes_controller.dart';
import '../../data/models/reporte_model.dart';
import '../../../../core/constants/categorias_reporte.dart';

import '../../../../core/widgets/marquee_text.dart';

class MisReportesScreen extends GetView<MisReportesController> {
  const MisReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Get.back();
              } else {
                Get.offAllNamed('/main', arguments: 3);
              }
            },
          ),
        ),
        title: MarqueeText(
          text: 'Los Reportes que has Generado',
          style: TextStyle(color: Colors.black, fontSize: 19.sp, fontWeight: FontWeight.bold),
          height: 24.h,
          umbral: 10,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
            onPressed: controller.toggleBusqueda,
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF3B82F6),
            ),
            onPressed: () => Get.toNamed('/crear-reporte'),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 15.h),
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: controller.mostrarBusqueda.value ? 60.h : 0,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: controller.mostrarBusqueda.value
                  ? TextField(
                      onChanged: controller.actualizarBusqueda,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar por sendero...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF3B82F6),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value)
                return const Center(child: CircularProgressIndicator());
              final lista = controller.reportesFiltrados;
              if (lista.isEmpty) {
                return Center(
                  child: Text(
                    'Aún no has creado ningún reporte.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.all(20.w),
                itemCount: lista.length,
                separatorBuilder: (_, __) => SizedBox(height: 15.h),
                itemBuilder: (context, index) {
                  final reporte = lista[index];
                  final cat = categoriaPorValor(reporte.categoria);
                  return Container(
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: reporte.fotoPortadaUrl != null
                              ? Image.network(
                                  reporte.fotoPortadaUrl!,
                                  width: 70.w,
                                  height: 70.w,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 70.w,
                                  height: 70.w,
                                  color: cat.color.withOpacity(0.15),
                                  child: Icon(cat.icono, color: cat.color),
                                ),
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.etiqueta, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                              Text(reporte.senderoNombre, style: TextStyle(fontSize: 13.sp, color: Colors.grey[500])),
                              SizedBox(height: 2.h),
                              MarqueeText(
                                text: reporte.descripcion,
                                style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                                height: 14.h,
                                umbral: 30,
                              ),
                              if (reporte.validado)
                                Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Text('✓ Validado', style: TextStyle(fontSize: 11.sp, color: Colors.green[700], fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Get.toNamed(
                            '/detalle-reporte',
                            arguments: reporte.id,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: const Text(
                            'Detalle',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
