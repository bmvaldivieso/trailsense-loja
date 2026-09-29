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
  final RxInt paginaActual = 0.obs;

  final PageController pageController = PageController();

  @override
  void onInit() {
    super.onInit();
    cargarMetricas();
  }

  Future<void> cargarMetricas() async {
    try {
      isLoading.value = true;
      metricas.value = await _repository.obtenerMetricas(periodo.value);
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

  Future<void> descargarPdf(String periodoDescarga) async {
    try {
      isDescargando.value = true;
      final bytes = await _repository.descargarPdf(periodoDescarga);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/metricas_personales_$periodoDescarga.pdf');
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