import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/crear_reporte_controller.dart';
import '../../../../core/constants/categorias_reporte.dart';

class CrearReporteScreen extends GetView<CrearReporteController> {
  const CrearReporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,               
        backgroundColor: const Color(0xFFF6F6FA), 
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1724)), onPressed: () => Get.back()),
        title: Text('Crear Reporte', style: TextStyle(color: const Color(0xFF0D1724), fontSize: 20.sp, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sendero: fijo o seleccionable
            Obx(() {
              if (controller.senderoIdFijo.value != null) {
                return Container(
                  padding: EdgeInsets.all(15.w),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r)),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFF8A00)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ubicación', style: TextStyle(fontSize: 12.sp, color: const Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
                            Text(controller.senderoNombreFijo.value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r)),
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(border: InputBorder.none, labelText: 'Selecciona el sendero'),
                  value: controller.senderoSeleccionado.value,
                  items: controller.senderosDisponibles
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre)))
                      .toList(),
                  onChanged: (valor) => controller.senderoSeleccionado.value = valor,
                ),
              );
            }),

            SizedBox(height: 20.h),
            Text('Agregar fotos (1 a 5):', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Obx(() => Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: [
                    ...controller.fotos.asMap().entries.map((entry) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.file(entry.value, width: 90.w, height: 90.w, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2, right: 2,
                              child: GestureDetector(
                                onTap: () => controller.quitarFoto(entry.key),
                                child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        )),
                    if (controller.fotos.length < CrearReporteController.maxFotos)
                      GestureDetector(
                        onTap: () => _mostrarOpcionesFoto(context),
                        child: Container(
                          width: 90.w, height: 90.w,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: Colors.grey.shade300)),
                          child: Icon(Icons.add_a_photo_outlined, color: const Color(0xFF00796B), size: 28.sp),
                        ),
                      ),
                  ],
                )),

            SizedBox(height: 20.h),
            Text('Detalle del incidente:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller.descripcionCtrl,
                    maxLength: CrearReporteController.maxCaracteres,
                    maxLines: 4,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Qué está ocurriendo, explica...', counterText: ''),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Obx(() => Text('*Quedan ${controller.caracteresRestantes.value} caracteres', style: TextStyle(fontSize: 10.sp, color: Colors.grey))),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
            Text('Selecciona el tipo de incidente:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r)),
              child: Column(
                children: categoriasReporte.map((cat) {
                  return Obx(() => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: GestureDetector(
                          onTap: () => controller.seleccionarCategoria(cat.valor),
                          child: Row(
                            children: [
                              Icon(cat.icono, color: cat.color, size: 20.r),
                              SizedBox(width: 10.w),
                              Expanded(child: Text(cat.etiqueta, style: TextStyle(fontSize: 14.sp))),
                              Container(
                                width: 20.w, height: 20.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: controller.categoriaSeleccionada.value == cat.valor ? const Color(0xFF6292F0) : Colors.grey, width: 2),
                                ),
                                child: controller.categoriaSeleccionada.value == cat.valor
                                    ? Center(child: Container(width: 10.w, height: 10.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6292F0))))
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ));
                }).toList(),
              ),
            ),

            SizedBox(height: 30.h),
            Obx(() => SizedBox(
                  width: double.infinity, height: 50.h,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.enviarReporte,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6292F0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                    child: controller.isLoading.value
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(height: 6.h),
                              Obx(() => Text(
                                    controller.estadoUbicacion.value.isEmpty ? 'Enviando...' : controller.estadoUbicacion.value,
                                    style: TextStyle(color: Colors.white, fontSize: 11.sp),
                                  )),
                            ],
                          )
                        : Text('Crear', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesFoto(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Tomar foto'), onTap: () { Get.back(); controller.agregarFotoDesdeCamara(); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Elegir de galería'), onTap: () { Get.back(); controller.agregarFotoDesdeGaleria(); }),
          ],
        ),
      ),
    );
  }
}