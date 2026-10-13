import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/metricas_model.dart'; // ajusta la ruta donde está MesKm

class GraficoKmMensual extends StatelessWidget {
  final List<MesKm> mensuales;
  final bool expandido;

  const GraficoKmMensual({super.key, required this.mensuales, this.expandido = false});

  @override
  Widget build(BuildContext context) {
    if (mensuales.isEmpty) {
      return Center(child: Text('Sin datos aún', style: TextStyle(color: Colors.grey, fontSize: 13.sp)));
    }
    final spots = mensuales.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.km))
        .toList();
    const verde = Color(0xFF2DD4BF);
    final fuente = expandido ? 12.0 : 10.0;

    return LineChart(LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: expandido ? 48 : 36,
            getTitlesWidget: (v, meta) => Text(
              v.toStringAsFixed(expandido ? 1 : 0),
              style: TextStyle(fontSize: fuente, color: Colors.grey[700]),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (value != i.toDouble() || i < 0 || i >= mensuales.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(mensuales[i].mes, style: TextStyle(fontSize: fuente)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      // Al tocar un punto muestra los km (solo útil en la versión ampliada)
      lineTouchData: LineTouchData(
        enabled: expandido,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (puntos) => puntos.map((p) {
            final mes = mensuales[p.x.toInt()].mes;
            return LineTooltipItem(
              '$mes\n${p.y.toStringAsFixed(3)} km',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: verde,
          barWidth: expandido ? 4 : 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: verde.withOpacity(0.1)),
        ),
      ],
    ));
  }
}