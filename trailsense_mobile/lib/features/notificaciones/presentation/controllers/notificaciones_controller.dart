import 'dart:async';
import 'package:get/get.dart';

import '../../data/models/notificacion_model.dart';
import '../../data/repositories/notificaciones_repository.dart';

class NotificacionesController extends GetxController {
  final NotificacionesRepository _repository = NotificacionesRepository();

  final RxList<NotificacionModel> notificaciones = <NotificacionModel>[].obs;
  final RxInt noLeidas = 0.obs;
  final RxBool isLoading = false.obs;

  final RxString busqueda = ''.obs;
  final RxString filtroTipo = ''.obs;
  final RxBool soloNoLeidas = false.obs;
  final RxBool mostrarBusqueda = false.obs;

  Timer? _timer;
  static const Duration intervaloActualizacion = Duration(minutes: 2);

  @override
  void onInit() {
    super.onInit();
    cargar();
    _timer = Timer.periodic(intervaloActualizacion, (_) => cargar(silencioso: true));
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> cargar({bool silencioso = false}) async {
    try {
      if (!silencioso) isLoading.value = true;
      final r = await _repository.listar();
      notificaciones.value = r.items;
      noLeidas.value = r.noLeidas;
    } catch (_) {
      if (!silencioso) Get.snackbar('Error', 'No se pudieron cargar tus notificaciones.');
    } finally {
      isLoading.value = false;
    }
  }

  List<NotificacionModel> get filtradas {
    var lista = notificaciones.toList();
    if (filtroTipo.value.isNotEmpty) lista = lista.where((n) => n.tipo == filtroTipo.value).toList();
    if (soloNoLeidas.value) lista = lista.where((n) => !n.leida).toList();
    final q = busqueda.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista.where((n) => n.titulo.toLowerCase().contains(q) || n.mensaje.toLowerCase().contains(q)).toList();
    }
    return lista;
  }

  bool get hayFiltros => filtroTipo.value.isNotEmpty || soloNoLeidas.value;

  void limpiarFiltros() {
    filtroTipo.value = '';
    soloNoLeidas.value = false;
  }

  void alternarBusqueda() {
    mostrarBusqueda.value = !mostrarBusqueda.value;
    if (!mostrarBusqueda.value) busqueda.value = '';
  }

  Future<void> abrirDetalle(NotificacionModel n) async {
    await Get.toNamed('/detalle-notificacion', arguments: n.id);
    cargar(silencioso: true);   // al volver, el detalle ya la marcó como leída
  }
}