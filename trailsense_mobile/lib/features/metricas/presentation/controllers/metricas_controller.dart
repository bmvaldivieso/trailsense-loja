import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/metricas_model.dart';
import '../../data/repositories/metricas_repository.dart';

class MetricasController extends GetxController {
  final MetricasRepository _repository = MetricasRepository();

  final Rx<MetricasPersonalesModel?> metricas = Rx<MetricasPersonalesModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isDescargando = false.obs;
  final RxString periodo = 'mes'.obs;
  final RxString mesSeleccionado = ''.obs;                
  final RxList<MesDisponible> meses = <MesDisponible>[].obs;  
  final RxInt paginaActual = 0.obs;

  final PageController pageController = PageController();

  @override
  void onInit() {
    super.onInit();
    cargarMetricas();
    cargarMeses();                                        
  }

  Future<void> cargarMeses() async {                       
    try {
      meses.value = await _repository.obtenerMeses();
    } catch (_) {}
  }

  String? get _mesActivo => periodo.value == 'mes_especifico' ? mesSeleccionado.value : null;

  String get etiquetaMesSeleccionado =>                    
      meses.firstWhereOrNull((m) => m.valor == mesSeleccionado.value)?.etiqueta ?? 'Mes específico';

  Future<void> cargarMetricas() async {
    try {
      isLoading.value = true;
      metricas.value = await _repository.obtenerMetricas(periodo.value, mes: _mesActivo);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar tus métricas.');
    } finally {
      isLoading.value = false;
    }
  }

  void cambiarPeriodo(String nuevo) {
    periodo.value = nuevo;
    cargarMetricas();
  }

  void seleccionarMes(String valor) {
    mesSeleccionado.value = valor;
    periodo.value = 'mes_especifico';
    cargarMetricas();
  }

  Future<void> descargarPdf(String periodoDescarga, {String? mes}) async {
    try {
      isDescargando.value = true;
      final bytes = await _repository.descargarPdf(periodoDescarga, mes: mes);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/metricas_personales_${mes ?? periodoDescarga}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Mis métricas personales - TrailSense Loja');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo generar el PDF.');
    } finally {
      isDescargando.value = false;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}