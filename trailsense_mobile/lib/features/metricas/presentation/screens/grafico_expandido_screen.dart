import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../data/models/metricas_model.dart';
import '../widgets/grafico_km_mensual.dart';

class GraficoExpandidoScreen extends StatelessWidget {
  final List<MesKm> mensuales;
  const GraficoExpandidoScreen({super.key, required this.mensuales});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          tooltip: 'Cerrar',
          onPressed: () => Get.back(),
        ),
        title: Text('Estadísticas Mensuales',
            style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 24.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kilómetros recorridos en los últimos 6 meses',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13.sp)),
              SizedBox(height: 4.h),
              Text('Toca un punto para ver el valor exacto.',
                  style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              SizedBox(height: 16.h),
              Expanded(child: GraficoKmMensual(mensuales: mensuales, expandido: true)),
            ],
          ),
        ),
      ),
    );
  }
}