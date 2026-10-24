import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/reporte_model.dart';
import '../../../../core/constants/categorias_reporte.dart';
import '../../../../core/widgets/visor_imagen.dart';

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

  /// Muestra toda la información de un reporte parecido. Al cerrarlo se vuelve a la lista.
  static Future<void> verDetalle(ReporteModel reporte) {
    return Get.dialog<void>(_DetalleSimilarDialog(reporte: reporte));
  }

  static Future<bool> confirmarVoto(ReporteModel reporte) async {
    final CategoriaReporte cat = categoriaPorValor(reporte.categoria);
    final bool? r = await Get.dialog<bool>(
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
    final bool? r = await Get.dialog<bool>(
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

// ------------------------------------------------------------------ lista de parecidos
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
              ...similares.map((ReporteModel r) => _TarjetaSimilar(reporte: r)),
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
    final CategoriaReporte cat = categoriaPorValor(reporte.categoria);
    final String? foto = reporte.fotos.isNotEmpty ? reporte.fotos.first.url : reporte.fotoPortadaUrl;

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
                    Text(reporte.fechaTexto, style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
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
              OutlinedButton(                                                  // NUEVO
                onPressed: () => ReporteSimilarDialogs.verDetalle(reporte),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('Detalle', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: () => Get.back(result: DecisionSimilar.votar(reporte)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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

// ------------------------------------------------------------- detalle de un parecido
class _DetalleSimilarDialog extends StatelessWidget {
  final ReporteModel reporte;
  const _DetalleSimilarDialog({required this.reporte});

  static String _estadoTexto(String estado) => switch (estado) {
        'aprobado' => 'Aprobado',
        'rechazado' => 'Rechazado',
        _ => 'Pendiente de validación',
      };

  @override
  Widget build(BuildContext context) {
    final CategoriaReporte cat = categoriaPorValor(reporte.categoria);
    final List<String> fotos = reporte.fotos.isNotEmpty
        ? reporte.fotos.map((FotoReporteModel f) => f.url).toList()
        : <String>[if (reporte.fotoPortadaUrl != null) reporte.fotoPortadaUrl!];
    final TextStyle estiloTitulo =
        TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: const Color(0xFF474B66));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.8.sh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado fijo
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 8.w, 8.h),
              child: Row(children: [
                Icon(cat.icono, color: cat.color, size: 22.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(cat.etiqueta, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  tooltip: 'Cerrar detalle',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            ),
            // Contenido con scroll
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fotos.isNotEmpty) ...[
                      SizedBox(
                        height: 150.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: fotos.length,
                          separatorBuilder: (BuildContext _, int __) => SizedBox(width: 8.w),
                          itemBuilder: (BuildContext ctx, int i) => GestureDetector(
                            onTap: () => abrirVisorImagen(ctx, fotos[i]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.network(fotos[i], width: fotos.length == 1 ? 0.7.sw : 200.w, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        fotos.length > 1
                            ? 'Desliza para ver las ${fotos.length} fotos · toca una para ampliarla'
                            : 'Toca la foto para ampliarla',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    _Fila(icono: Icons.terrain, texto: reporte.senderoNombre),
                    _Fila(icono: Icons.calendar_today_outlined, texto: reporte.fechaTexto),
                    _Fila(
                      icono: Icons.person_outline,
                      texto: 'Reportado por: ${reporte.usuarioNombre.isNotEmpty ? reporte.usuarioNombre : 'Senderista'}',
                    ),
                    _Fila(icono: Icons.flag_outlined, texto: _estadoTexto(reporte.estado)),
                    _Fila(
                      icono: Icons.thumb_up_alt_outlined,
                      texto: '${reporte.votosConfirmacion} '
                          '${reporte.votosConfirmacion == 1 ? 'voto de confirmación' : 'votos de confirmación'}',
                    ),
                    SizedBox(height: 10.h),
                    Text('DESCRIPCIÓN:', style: estiloTitulo),
                    SizedBox(height: 4.h),
                    Text(
                      reporte.descripcion,
                      style: TextStyle(fontSize: 13.sp, color: const Color(0xFF474B66), height: 1.4),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            // Botón fijo para volver a la lista
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
              child: SizedBox(
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Cerrar detalle',
                      style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Fila({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18.r, color: const Color(0xFF3B82F6)),
          SizedBox(width: 8.w),
          Expanded(child: Text(texto, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp))),
        ],
      ),
    );
  }
}