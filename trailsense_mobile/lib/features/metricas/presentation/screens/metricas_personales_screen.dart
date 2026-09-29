import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/metricas_controller.dart';
import '../../data/models/metricas_model.dart';

class MetricasPersonalesScreen extends GetView<MetricasController> {
  const MetricasPersonalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Get.back()),
        title: Text('Métricas Personales', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        actions: [
          Obx(() => IconButton(
                icon: controller.isDescargando.value
                    ? SizedBox(width: 20.w, height: 20.h, child: const CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF3B82F6)),
                onPressed: controller.isDescargando.value ? null : () => _mostrarSelectorPeriodo(context),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value || controller.metricas.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final m = controller.metricas.value!;

        return Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (i) => controller.paginaActual.value = i,
                children: [_buildPaginaResumen(m), _buildPaginaEstadisticas(m)],
              ),
            ),
            SizedBox(height: 8.h),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (i) {
                    final activo = controller.paginaActual.value == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: activo ? 22.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: activo ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    );
                  }),
                )),
            SizedBox(height: 16.h),
          ],
        );
      }),
    );
  }

  Widget _buildEncabezado(MetricasPersonalesModel m) {
    return Column(
      children: [
        CircleAvatar(
          radius: 90.r,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: m.fotoUrl != null ? NetworkImage(m.fotoUrl!) : null,
          child: m.fotoUrl == null ? Icon(Icons.person, size: 90.sp, color: Colors.grey) : null,
        ),
        SizedBox(height: 12.h),
        Text(m.nombre, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaginaResumen(MetricasPersonalesModel m) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          _buildEncabezado(m),
          SizedBox(height: 16.h),
          _buildSelectorPeriodo(),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
            child: Column(
              children: [
                _buildFila('Nombre', m.nombre),
                _buildFila('Km', '${m.distanciaKm.toStringAsFixed(3)} km'),
                _buildFila('Pasos', '${m.pasos}'),
                _buildFila('Tiempo', m.tiempoTexto),
                const Divider(height: 24),
                _buildFila('Reportes', '${m.reportes}'),
                _buildFila('Recorridos', '${m.recorridos}'),
                _buildFila('Miembro desde', m.fechaRegistro),
                _buildFilaEstado(m.estado),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorPeriodo() {
    final opciones = {'dia': 'Día', 'semana': 'Semana', 'mes': 'Mes', 'todo': 'Todo'};
    return Obx(() => Wrap(
          spacing: 8.w,
          children: opciones.entries.map((e) {
            final seleccionado = controller.periodo.value == e.key;
            return ChoiceChip(
              label: Text(e.value),
              selected: seleccionado,
              selectedColor: const Color(0xFF3B82F6),
              labelStyle: TextStyle(color: seleccionado ? Colors.white : Colors.black87, fontSize: 12.sp),
              backgroundColor: Colors.white,
              onSelected: (_) => controller.cambiarPeriodo(e.key),
            );
          }).toList(),
        ));
  }

  Widget _buildFila(String label, String valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2D3142))),
          Text(valor, style: TextStyle(fontSize: 14.sp, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildFilaEstado(String estado) {
    final colores = {'Excelente': Colors.green, 'Regular': Colors.orange, 'Inactivo': Colors.grey};
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Status', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2D3142))),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(color: colores[estado] ?? Colors.grey, borderRadius: BorderRadius.circular(20.r)),
            child: Text(estado, style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginaEstadisticas(MetricasPersonalesModel m) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          _buildEncabezado(m),
          SizedBox(height: 20.h),

          Align(alignment: Alignment.centerLeft, child: Text('Estadísticas Mensuales', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold))),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity, height: 220.h, padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
            child: _buildGraficoLinea(m.mensuales),
          ),

          SizedBox(height: 20.h),
          Align(alignment: Alignment.centerLeft, child: Text('Estadísticas Vitalicias', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold))),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity, padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
            child: Column(
              children: [
                _buildFilaVitalicia(Icons.timer_outlined, 'Tiempo Movimiento', '${m.tiempoMovimientoH} H', Colors.teal),
                _buildFilaVitalicia(Icons.sync_alt, 'Distancia Recorrida', '${m.distanciaVitaliciaKm.toStringAsFixed(3)} KM', Colors.blue),
                _buildFilaVitalicia(Icons.speed, 'Velocidad Promedio', '${m.velocidadPromedioKmh} KM/H', Colors.pink),
              ],
            ),
          ),

          SizedBox(height: 20.h),
          Align(alignment: Alignment.centerLeft, child: Text('Estadística de Aplicación', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold))),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity, height: 220.h, padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
            child: _buildGraficoPastel(m),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildFilaVitalicia(IconData icono, String label, String valor, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 36.w, height: 36.h,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(icono, color: color, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, color: const Color(0xFF2D3142)))),
          Text(valor, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGraficoLinea(List<MesKm> mensuales) {
    if (mensuales.isEmpty) return Center(child: Text('Sin datos aún', style: TextStyle(color: Colors.grey[500])));

    final spots = mensuales.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.km)).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= mensuales.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 6), child: Text(mensuales[i].mes, style: const TextStyle(fontSize: 10)));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, color: const Color(0xFF2DD4BF), barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF2DD4BF).withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoPastel(MetricasPersonalesModel m) {
    final total = m.pctRecorridos + m.pctReportes + m.pctFotos;
    if (total == 0) return Center(child: Text('Aún no hay actividad registrada', style: TextStyle(color: Colors.grey[500])));

    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sectionsSpace: 2, centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(value: m.pctRecorridos.toDouble(), color: const Color(0xFF1E293B), title: '${m.pctRecorridos}%', radius: 55, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              PieChartSectionData(value: m.pctReportes.toDouble(), color: const Color(0xFFF97316), title: '${m.pctReportes}%', radius: 55, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              PieChartSectionData(value: m.pctFotos.toDouble(), color: const Color(0xFFD946EF), title: '${m.pctFotos}%', radius: 55, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          )),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _leyenda('Recorridos', const Color(0xFF1E293B)),
            _leyenda('Reportes', const Color(0xFFF97316)),
            _leyenda('Fotos', const Color(0xFFD946EF)),
          ],
        ),
      ],
    );
  }

  Widget _leyenda(String texto, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(children: [
        Container(width: 10.w, height: 10.h, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6.w),
        Text(texto, style: TextStyle(fontSize: 11.sp)),
      ]),
    );
  }

  void _mostrarSelectorPeriodo(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descargar métricas en PDF', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            Text('Selecciona el intervalo de tiempo', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
            SizedBox(height: 16.h),
            _opcionPdf('dia', 'Día'),
            _opcionPdf('semana', 'Semana'),
            _opcionPdf('mes', 'Mes'),
            _opcionPdf('todo', 'Todo el historial'),
          ],
        ),
      ),
    );
  }

  Widget _opcionPdf(String valor, String etiqueta) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF3B82F6)),
      title: Text(etiqueta),
      onTap: () {
        Get.back();
        controller.descargarPdf(valor);
      },
    );
  }
}