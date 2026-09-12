import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/senderos_controller.dart';

void mostrarFiltrosSenderos(
  BuildContext context,
  SenderosController controller, {
  bool mostrarBotonLimpiar = false,
}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtrar senderos', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              if (mostrarBotonLimpiar) // Condicional
                Obx(() => (controller.filtroDificultad.value.isNotEmpty || controller.filtroEstado.value.isNotEmpty)
                    ? TextButton(
                        onPressed: () {
                          controller.limpiarFiltros();
                          Get.back();
                        },
                        child: const Text('Limpiar', style: TextStyle(color: Color(0xFF3B82F6))),
                      )
                    : const SizedBox.shrink()),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Dificultad',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: ['baja', 'media', 'alta'].map((d) {
              final seleccionado = controller.filtroDificultad.value == d;
              return ChoiceChip(
                label: Text(d),
                selected: seleccionado,
                selectedColor: const Color(0xFF3B82F6),
                labelStyle: TextStyle(
                  color: seleccionado ? Colors.white : Colors.black87,
                ),
                backgroundColor: const Color(0xFFF0F2F5),
                onSelected: (_) {
                  controller.aplicarFiltro(dificultad: d);
                  Get.back();
                },
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
          Text(
            'Estado',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: ['bueno', 'alerta', 'critico'].map((e) {
              final seleccionado = controller.filtroEstado.value == e;
              return ChoiceChip(
                label: Text(e),
                selected: seleccionado,
                selectedColor: const Color(0xFF3B82F6),
                labelStyle: TextStyle(
                  color: seleccionado ? Colors.white : Colors.black87,
                ),
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
