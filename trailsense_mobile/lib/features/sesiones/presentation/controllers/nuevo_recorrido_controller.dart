import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:trailsense_mobile/features/sesiones/presentation/controllers/sesiones_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/sesion_model.dart';
import '../../data/models/punto_gps_model.dart';
import '../../data/repositories/sesiones_repository.dart';

import 'package:permission_handler/permission_handler.dart';

class NuevoRecorridoController extends GetxController {
  final SesionesRepository _repository = SesionesRepository();

  final RxString estado = 'inicial'.obs; // inicial | grabando | pausada | finalizada
  final Rx<SesionModel?> sesion = Rx<SesionModel?>(null);

  final RxDouble distanciaKm = 0.0.obs;
  final RxInt duracionSegundos = 0.obs;
  final RxDouble velocidadPromedioKmh = 0.0.obs;
  final RxInt pasos = 0.obs;

  StreamSubscription<Position>? _posicionSub;
  StreamSubscription<StepCount>? _pasosSub;
  Timer? _timerDuracion;
  Timer? _timerEnvioLotes;

  final List<PuntoGpsLocal> _bufferPuntos = [];
  Position? _ultimaPosicion;
  int? _pasosBase;
  int _segundosPausados = 0;
  DateTime? _momentoPausa;

  static const Duration intervaloEnvio = Duration(seconds: 15);

  @override
  void onClose() {
    _detenerStreams();
    WakelockPlus.disable();
    super.onClose();
  }

  Future<bool> _asegurarPermisoPasos() async {
    var estado = await Permission.activityRecognition.status;
    if (!estado.isGranted) {
      estado = await Permission.activityRecognition.request();
    }
    return estado.isGranted;
  }

  Future<void> iniciarRecorrido({int? senderoId}) async {
    try {
      final permisoOk = await _asegurarPermisoUbicacion();
      if (!permisoOk) {
        Get.snackbar('Permiso requerido', 'Activa el permiso de ubicación para iniciar el recorrido.');
        return;
      }

      final nuevaSesion = await _repository.iniciarSesion(senderoId: senderoId);
      sesion.value = nuevaSesion;
      estado.value = 'grabando';

      distanciaKm.value = 0;
      duracionSegundos.value = 0;
      velocidadPromedioKmh.value = 0;
      pasos.value = 0;
      _segundosPausados = 0;
      _bufferPuntos.clear();
      _ultimaPosicion = null;
      _pasosBase = null;

      await WakelockPlus.enable();
      _iniciarCapturaGps();
      final permisoPasos = await _asegurarPermisoPasos();
      if (permisoPasos) {
        _iniciarContadorPasos();
      } else {
        Get.snackbar('Permiso de actividad física', 'Sin este permiso los pasos no se contarán.');
      }
      _iniciarTemporizador();
      _iniciarEnvioPeriodico();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo iniciar el recorrido.');
    }
  }

  Future<bool> _asegurarPermisoUbicacion() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) return false;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return permiso == LocationPermission.always || permiso == LocationPermission.whileInUse;
  }

  // ============================================================
  // Sensado oportunista: captura automática de la traza GPS
  // ============================================================
  void _iniciarCapturaGps() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // solo notifica si se movió al menos 5 metros
    );

    _posicionSub = Geolocator.getPositionStream(locationSettings: settings).listen((posicion) {
      if (estado.value != 'grabando') return;

      _bufferPuntos.add(PuntoGpsLocal(
        lat: posicion.latitude,
        lon: posicion.longitude,
        capturadoEn: DateTime.now().toUtc(),
        precisionM: posicion.accuracy,
        altitudM: posicion.altitude,
        velocidadMps: posicion.speed,
      ));

      if (_ultimaPosicion != null) {
        final distanciaTramo = Geolocator.distanceBetween(
          _ultimaPosicion!.latitude,
          _ultimaPosicion!.longitude,
          posicion.latitude,
          posicion.longitude,
        );
        distanciaKm.value += distanciaTramo / 1000;
        _actualizarVelocidadPromedio();
      }

      _ultimaPosicion = posicion;
    });
  }

  // ============================================================
  // Sensado oportunista adicional: contador de pasos (acelerómetro)
  // ============================================================
  void _iniciarContadorPasos() {
    _pasosSub = Pedometer.stepCountStream.listen(
      (evento) {
        _pasosBase ??= evento.steps;
        pasos.value = evento.steps - _pasosBase!;
      },
      onError: (_) {
        _pasosSub = Pedometer.stepCountStream.listen(
          (evento) {
            _pasosBase ??= evento.steps;
            pasos.value = evento.steps - _pasosBase!;
          },
          onError: (e) {
            debugPrint('Error pedómetro: $e');
          },
        );
      },
    );
  }

  void _iniciarTemporizador() {
    _timerDuracion?.cancel();
    _timerDuracion = Timer.periodic(const Duration(seconds: 1), (_) {
      if (estado.value == 'grabando') {
        duracionSegundos.value++;
        _actualizarVelocidadPromedio();
      }
    });
  }

  void _actualizarVelocidadPromedio() {
    if (duracionSegundos.value > 0) {
      velocidadPromedioKmh.value = distanciaKm.value / (duracionSegundos.value / 3600);
    }
  }

  // ============================================================
  // Envío periódico de lotes al backend (oportunista)
  // ============================================================
  void _iniciarEnvioPeriodico() {
    _timerEnvioLotes?.cancel();
    _timerEnvioLotes = Timer.periodic(intervaloEnvio, (_) => _enviarLoteActual());
  }

  Future<void> _enviarLoteActual() async {
    if (_bufferPuntos.isEmpty || sesion.value == null) return;

    final lote = List<PuntoGpsLocal>.from(_bufferPuntos);
    _bufferPuntos.clear();

    try {
      await _repository.enviarPuntos(sesion.value!.id, lote);
    } catch (e) {
      _bufferPuntos.insertAll(0, lote); // reintenta en el siguiente ciclo
    }
  }

  Future<void> pausarRecorrido() async {
    if (sesion.value == null || estado.value != 'grabando') return;

    await _enviarLoteActual();
    try {
      await _repository.pausarSesion(sesion.value!.id);
      estado.value = 'pausada';
      _momentoPausa = DateTime.now();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo pausar el recorrido.');
    }
  }

  Future<void> reanudarRecorrido() async {
    if (sesion.value == null || estado.value != 'pausada') return;

    try {
      await _repository.reanudarSesion(sesion.value!.id);
      if (_momentoPausa != null) {
        _segundosPausados += DateTime.now().difference(_momentoPausa!).inSeconds;
        _momentoPausa = null;
      }
      estado.value = 'grabando';
    } catch (e) {
      Get.snackbar('Error', 'No se pudo reanudar el recorrido.');
    }
  }

  Future<void> finalizarRecorrido() async {
    if (sesion.value == null) return;

    await _enviarLoteActual();
    _detenerStreams();
    await WakelockPlus.disable();

    try {
      final resultado = await _repository.finalizarSesion(
        sesion.value!.id,
        tiempoPausadoSegundos: _segundosPausados,
        pasos: pasos.value,
      );
      sesion.value = resultado;
      estado.value = 'finalizada';

      distanciaKm.value = resultado.distanciaKm;
      duracionSegundos.value = resultado.duracionSegundos;
      velocidadPromedioKmh.value = resultado.velocidadPromedioKmh;

      // Refresca la lista de recorridos inmediatamente
      if (Get.isRegistered<SesionesController>()) {
        Get.find<SesionesController>().cargarSesiones();
      }

      Get.offNamed('/detalle-recorrido', arguments: resultado.id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo finalizar el recorrido.');
    }
  }

  void _detenerStreams() {
    _posicionSub?.cancel();
    _pasosSub?.cancel();
    _timerDuracion?.cancel();
    _timerEnvioLotes?.cancel();
  }

  String get duracionFormateada {
    final d = Duration(seconds: duracionSegundos.value);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h == '00' ? '$m:$s' : '$h:$m:$s';
  }
}