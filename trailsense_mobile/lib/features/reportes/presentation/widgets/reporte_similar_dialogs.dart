import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/reporte_model.dart';
import '../../../../core/constants/categorias_reporte.dart';

/// Resultado de la primera pregunta: votar por un reporte existente o crear uno nuevo.
class DecisionSimilar {
  final ReporteModel? votarPor; // null = "No es la misma"
  const DecisionSimilar.votar(ReporteModel reporte) : votarPor = reporte;
  const DecisionSimilar.crearNueva() : votarPor = null;
}

class ReporteSimilarDialogs {
  /// null = el usuario canceló todo el proceso.
  static Future<DecisionSimilar?> preguntar(List<ReporteModel> similares) {
    return Get.dialog<DecisionSimilar>(
      _SimilaresDialog(similares: similares),
      barrierDismissible: false,
    );
  }

  static Future<bool> confirmarVoto(ReporteModel reporte) async {
    final cat = categoriaPorValor(reporte.categoria);
    final r = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('¿Confirmar tu voto?'),
        content: Text(
          'Vas a votar por el reporte de "${cat.etiqueta}" en ${reporte.senderoNombre}.\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Confirmar voto')),
        ],
      ),
      barrierDismissible: false,
    );
    return r ?? false;
  }

  static Future<bool> confirmarNoEsLaMisma() async {
    final r = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('¿Seguro que no es la misma?'),
        content: const Text('Si continúas, se creará una incidencia nueva con los datos que ingresaste.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Volver')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Sí, crear nueva')),
        ],
      ),
      barrierDismissible: false,
    );
    return r ?? false;
  }
}

class _SimilaresDialog extends StatelessWidget {
  final List<ReporteModel> similares;
  const _SimilaresDialog({required this.similares});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ya existe un reporte parecido'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hay reportes recientes de esta categoría en este mismo lugar. '
                'Si es el mismo problema, confírmalo con tu voto en lugar de crear uno nuevo.',
                style: TextStyle(fontSize: 13.sp, color: Colors.black54),
              ),
              SizedBox(height: 12.h),
              ...similares.map((r) => _TarjetaSimilar(reporte: r)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Get.back(result: const DecisionSimilar.crearNueva()),
          child: const Text('No es la misma'),
        ),
      ],
    );
  }
}

class _TarjetaSimilar extends StatelessWidget {
  final ReporteModel reporte;
  const _TarjetaSimilar({required this.reporte});

  @override
  Widget build(BuildContext context) {
    final cat = categoriaPorValor(reporte.categoria);
    final foto = reporte.fotos.isNotEmpty ? reporte.fotos.first.url : reporte.fotoPortadaUrl;
    final f = reporte.fechaCreacion.toLocal();
    final fecha = '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (foto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(foto, width: 70.w, height: 70.w, fit: BoxFit.cover),
                ),
              if (foto != null) SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(cat.icono, size: 16.r, color: cat.color),
                      SizedBox(width: 6.w),
                      Expanded(child: Text(cat.etiqueta, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp))),
                    ]),
                    SizedBox(height: 2.h),
                    Text(fecha, style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                    SizedBox(height: 4.h),
                    Text(
                      reporte.descripcion,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF474B66)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 14.r, color: const Color(0xFF3B82F6)),
              SizedBox(width: 4.w),
              Text('${reporte.votosConfirmacion}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Get.back(result: DecisionSimilar.votar(reporte)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('Es la misma', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}