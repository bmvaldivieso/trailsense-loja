import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/punto_gps_model.dart';
import '../../data/models/sesion_model.dart';
import '../../data/repositories/sesiones_repository.dart';
import 'sesiones_controller.dart';
import '../../../../core/location/ajustes_gps.dart';
import '../../../../core/location/filtro_kalman_gps.dart';
import '../../../notificaciones/data/repositories/notificaciones_repository.dart';
import '../../../notificaciones/presentation/controllers/notificaciones_controller.dart';

import 'package:sensors_plus/sensors_plus.dart';
import '../../../../core/sensors/detector_pasos.dart';

class NuevoRecorridoController extends GetxController {
  final SesionesRepository _repository = SesionesRepository();

  final RxString estado = 'inicial'.obs; // inicial | grabando | pausada | finalizada
  final Rx<SesionModel?> sesion = Rx<SesionModel?>(null);

  final RxDouble distanciaKm = 0.0.obs;
  final RxInt duracionSegundos = 0.obs;
  final RxDouble velocidadPromedioKmh = 0.0.obs;
  final RxInt pasos = 0.obs;



  // ---- Requisitos para iniciar (se verifican en cada entrada a la pantalla) ----
  final RxBool gpsActivo = false.obs;
  final RxBool permisoUbicacion = false.obs;
  final RxBool ubicacionPrecisa = false.obs;
  final RxBool permisoActividad = false.obs;
  final RxBool ubicacionBloqueada = false.obs;   // negado permanentemente: solo desde Ajustes
  final RxBool actividadBloqueada = false.obs;
  final RxBool verificando = false.obs;

  bool get requisitosListos =>
      gpsActivo.value && permisoUbicacion.value && ubicacionPrecisa.value && permisoActividad.value;

  StreamSubscription<ServiceStatus>? _servicioGpsSub;
  AppLifecycleListener? _cicloVida;
  Future<void>? _verificacionEnCurso;






  final RxBool comprobando = false.obs;   // comprobación manual (indicador visible)
  final RxBool resolviendo = false.obs;   // hay una solicitud de permiso en curso

  // Android dejó de mostrar el diálogo: se recuerda mientras la pantalla está abierta
  bool _ubicacionSinDialogo = false;
  bool _actividadSinDialogo = false;

  /// Una respuesta "denegado" más rápida que esto significa que el sistema no mostró ventana.
  static const int _umbralSinDialogoMs = 500;

  List<String> get requisitosFaltantes => <String>[
        if (!gpsActivo.value) 'GPS del teléfono',
        if (!permisoUbicacion.value) 'Permiso de ubicación',
        if (permisoUbicacion.value && !ubicacionPrecisa.value) 'Ubicación precisa',
        if (!permisoActividad.value) 'Actividad física',
      ];





  StreamSubscription<Position>? _posicionSub;
  StreamSubscription<StepCount>? _pasosSub;
  Timer? _timerDuracion;
  Timer? _timerEnvioLotes;

  final List<PuntoGpsLocal> _bufferPuntos = [];
  int _segundosPausados = 0;
  DateTime? _momentoPausa;
  DateTime? _inicioLocal;
  bool _iniciando = false;

  // ---- Calidad de la traza ----
  static const double _precisionMaximaM = 25;         // lecturas peores no entran a la traza
  static const double _velocidadMaximaMps = 7;        // ~25 km/h: salto imposible caminando
  static const double _avanceMinimoM = 3;             // nunca registrar avances menores a esto
  static const double _factorPrecision = 0.6;         // o menores al 60 % del error de la lectura
  static const Duration _intervaloLatido = Duration(seconds: 30);  // punto aunque esté quieto
  static const Duration _esperaPosicionInicial = Duration(seconds: 3);
  static const Duration _vigenciaLectura = Duration(seconds: 15);

  final FiltroKalmanGps _kalman = FiltroKalmanGps();
  Position? _ultimaLectura;                            // última lectura cruda, de cualquier calidad
  ({double lat, double lon, DateTime ts})? _ancla;    // último punto aceptado (suavizado)
  DateTime? _ultimoGuardado;

  // ---- Pasos ----
  int? _pasosBase;
  int? _ultimoConteo;
  int? _conteoAlPausar;
  int _pasosEnPausa = 0;
  bool _reintentoPasos = false;
  bool _contadorActivo = false;      // el contador del sistema ya reportó avance
  int _pasosEstimados = 0;           // acelerómetro, solo hasta que el contador responda
  final DetectorPasos _detector = DetectorPasos();
  StreamSubscription<AccelerometerEvent>? _aceleracionSub;

  bool _nuevoTramo = false;          // el próximo punto guardado inicia un tramo (tras reanudar)

  static const Duration intervaloEnvio = Duration(seconds: 15);

  final NotificacionesRepository _notifRepository = NotificacionesRepository();
  DateTime? _ultimaConsultaProximidad;
  static const Duration intervaloProximidad = Duration(seconds: 60);

  @override
  void onReady() {
    super.onReady();
    verificarRequisitos(solicitar: true);   // al entrar: pide lo que falte

    // GPS encendido/apagado desde la barra de notificaciones: se refleja al instante
    _servicioGpsSub = Geolocator.getServiceStatusStream().listen((ServiceStatus s) {
      gpsActivo.value = s == ServiceStatus.enabled;
      if (!gpsActivo.value && estado.value == 'grabando') {
        Get.snackbar('GPS desactivado', 'Vuelve a activar el GPS: el recorrido no está registrando tu ubicación.',
            duration: const Duration(seconds: 6));
      }
      if (gpsActivo.value) verificarRequisitos();
    }, onError: (Object _) {});

    // Al volver de Ajustes se vuelve a comprobar sin que el usuario toque nada
    _cicloVida = AppLifecycleListener(onResume: () => verificarRequisitos());
  }

  @override
  void onClose() {
    _servicioGpsSub?.cancel();
    _cicloVida?.dispose();
    _detenerStreams();
    WakelockPlus.disable();
    super.onClose();
  }

  // ============================================================
  // Inicio: sensores calientes antes de crear la sesión
  // ============================================================
  Future<void> iniciarRecorrido({int? senderoId}) async {
    if (_iniciando || estado.value == 'grabando' || estado.value == 'pausada') return;
    _iniciando = true;
    try {
      // Última comprobación justo antes de iniciar (el usuario pudo apagar el GPS hace un segundo)
      await verificarRequisitos();
      if (!requisitosListos) {
        Get.snackbar('Faltan requisitos', 'Completa lo indicado en pantalla para iniciar el recorrido.');
        return;
      }

      _reiniciarEstadoLocal();
      _iniciarCapturaGps();       // precalentamiento del GPS
      _iniciarEstimadorPasos();   // pasos visibles desde el primer segundo
      _iniciarContadorPasos();    // contador exacto (el permiso ya está garantizado)

      final Position? posicionInicial = await _posicionInicialRapida();

      final SesionModel nuevaSesion = await _repository.iniciarSesion(
        senderoId: senderoId,
        lat: posicionInicial?.latitude,
        lon: posicionInicial?.longitude,
      );
      sesion.value = nuevaSesion;
      _inicioLocal = DateTime.now();
      estado.value = 'grabando';

      _sembrarPuntoInicial();
      _iniciarTemporizador();
      _iniciarEnvioPeriodico();
      await WakelockPlus.enable();
    } catch (e) {
      _detenerStreams();
      estado.value = 'inicial';
      Get.snackbar('Error', 'No se pudo iniciar el recorrido.');
    } finally {
      _iniciando = false;
    }
  }

  void _reiniciarEstadoLocal() {
    distanciaKm.value = 0;
    duracionSegundos.value = 0;
    velocidadPromedioKmh.value = 0;
    pasos.value = 0;
    _segundosPausados = 0;
    _momentoPausa = null;
    _inicioLocal = null;
    _bufferPuntos.clear();
    _kalman.reiniciar();
    _ancla = null;
    _ultimoGuardado = null;
    _ultimaLectura = null;
    _pasosBase = null;
    _ultimoConteo = null;
    _conteoAlPausar = null;
    _pasosEnPausa = 0;
    _reintentoPasos = false;
    _contadorActivo = false;
    _pasosEstimados = 0;
    _nuevoTramo = false;
  }

  /// Comprueba los 4 requisitos. Con [solicitar], muestra los diálogos del sistema que aún se puedan mostrar.
  Future<void> verificarRequisitos({bool solicitar = false}) {
    return _verificacionEnCurso ??= _verificar(solicitar).whenComplete(() => _verificacionEnCurso = null);
  }

  Future<void> _verificar(bool solicitar) async {
    verificando.value = true;
    try {
      gpsActivo.value = await Geolocator.isLocationServiceEnabled();

      PermissionStatus ubicacion = await Permission.locationWhenInUse.status;
      if (solicitar && ubicacion.isDenied && !_ubicacionSinDialogo) {
        final ({PermissionStatus estado, bool sinDialogo}) r = await _solicitar(Permission.locationWhenInUse);
        ubicacion = r.estado;
        if (r.sinDialogo) _ubicacionSinDialogo = true;
      }
      permisoUbicacion.value = ubicacion.isGranted || ubicacion.isLimited;
      if (permisoUbicacion.value) _ubicacionSinDialogo = false;
      ubicacionBloqueada.value = !permisoUbicacion.value &&
          (ubicacion.isPermanentlyDenied || ubicacion.isRestricted || _ubicacionSinDialogo);

      ubicacionPrecisa.value = permisoUbicacion.value &&
          await Geolocator.getLocationAccuracy() == LocationAccuracyStatus.precise;

      PermissionStatus actividad = await Permission.activityRecognition.status;
      if (solicitar && actividad.isDenied && !_actividadSinDialogo) {
        final ({PermissionStatus estado, bool sinDialogo}) r = await _solicitar(Permission.activityRecognition);
        actividad = r.estado;
        if (r.sinDialogo) _actividadSinDialogo = true;
      }
      permisoActividad.value = actividad.isGranted;
      if (permisoActividad.value) _actividadSinDialogo = false;
      actividadBloqueada.value =
          !permisoActividad.value && (actividad.isPermanentlyDenied || actividad.isRestricted || _actividadSinDialogo);
    } catch (e) {
      debugPrint('Error verificando requisitos: $e');
    } finally {
      verificando.value = false;
    }
  }

  /// Pide un permiso y detecta si Android lo negó sin mostrar ninguna ventana.
  Future<({PermissionStatus estado, bool sinDialogo})> _solicitar(Permission permiso) async {
    final Stopwatch reloj = Stopwatch()..start();
    final PermissionStatus estado = await permiso.request();
    final bool sinDialogo = !estado.isGranted && !estado.isLimited && reloj.elapsedMilliseconds < _umbralSinDialogoMs;
    return (estado: estado, sinDialogo: sinDialogo);
  }

  /// Botón "Volver a comprobar": duración mínima visible y resultado explícito.
  Future<void> comprobarManualmente() async {
    if (comprobando.value) return;
    comprobando.value = true;
    try {
      await Future.wait<void>(<Future<void>>[
        verificarRequisitos(),
        Future<void>.delayed(const Duration(milliseconds: 800)),
      ]);
    } finally {
      comprobando.value = false;
    }
    final List<String> faltan = requisitosFaltantes;
    Get.snackbar(
      faltan.isEmpty ? 'Todo listo' : 'Aún falta',
      faltan.isEmpty ? 'Ya puedes iniciar el recorrido.' : faltan.join(' · '),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
    );
  }

  Future<void> resolverGps() async {
    try {
      await Geolocator.openLocationSettings();   // al volver, onResume verifica de nuevo
    } catch (e) {
      Get.snackbar('GPS', 'Activa la ubicación desde la barra de notificaciones del teléfono.');
    }
  }

  Future<void> resolverUbicacion() => _resolverPermiso(
        permiso: Permission.locationWhenInUse,
        bloqueado: ubicacionBloqueada.value,
        marcarSinDialogo: () => _ubicacionSinDialogo = true,
        ruta: 'Ajustes > Aplicaciones > TrailSense > Permisos > Ubicación > '
            '"Permitir solo mientras se usa la app" y activa "Usar ubicación precisa".',
      );

  Future<void> resolverActividad() => _resolverPermiso(
        permiso: Permission.activityRecognition,
        bloqueado: actividadBloqueada.value,
        marcarSinDialogo: () => _actividadSinDialogo = true,
        ruta: 'Ajustes > Aplicaciones > TrailSense > Permisos > Actividad física > "Permitir".',
      );

  Future<void> resolverPrecision() async {
    if (resolviendo.value) return;
    resolviendo.value = true;
    try {
      // Android 12+: volver a pedir muestra el diálogo "cambiar a ubicación precisa"
      await _solicitar(Permission.locationWhenInUse);
      await verificarRequisitos();
      if (!ubicacionPrecisa.value) {
        await _explicarYAbrirAjustes(
          'TrailSense necesita la ubicación precisa para que el recorrido no se desvíe.\n\n'
          'Ve a Ajustes > Aplicaciones > TrailSense > Permisos > Ubicación y activa "Usar ubicación precisa".',
        );
      }
    } catch (e) {
      debugPrint('Error pidiendo ubicación precisa: $e');
      await _explicarYAbrirAjustes('Activa "Usar ubicación precisa" en los permisos de ubicación de TrailSense.');
    } finally {
      resolviendo.value = false;
      await verificarRequisitos();
    }
  }

  Future<void> _resolverPermiso({
    required Permission permiso,
    required bool bloqueado,
    required void Function() marcarSinDialogo,
    required String ruta,
  }) async {
    if (resolviendo.value) return;
    resolviendo.value = true;
    try {
      if (bloqueado) {
        await _explicarYAbrirAjustes('Android ya no muestra la ventana de este permiso porque se negó antes.\n\n$ruta');
        return;
      }
      final ({PermissionStatus estado, bool sinDialogo}) r = await _solicitar(permiso);
      if (r.sinDialogo || r.estado.isPermanentlyDenied || r.estado.isRestricted) {
        marcarSinDialogo();
        await _explicarYAbrirAjustes('Android no mostró la ventana de permisos porque se negó antes.\n\n$ruta');
      }
    } catch (e) {
      debugPrint('Error solicitando permiso: $e');
      await _explicarYAbrirAjustes('No se pudo mostrar la ventana de permisos.\n\n$ruta');
    } finally {
      resolviendo.value = false;
      await verificarRequisitos();
    }
  }

  Future<void> _explicarYAbrirAjustes(String mensaje) async {
    final bool? abrir = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Activa el permiso en Ajustes'),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Ahora no')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Abrir ajustes')),
        ],
      ),
    );
    if (abrir ?? false) await openAppSettings();   // al volver, onResume verifica de nuevo
  }

  /// Posición para detectar el sendero sin esperar a una lectura precisa (antes: getCurrentPosition).
  Future<Position?> _posicionInicialRapida() async {
    if (_ultimaLectura != null) return _ultimaLectura;
    try {
      final Position? conocida = await Geolocator.getLastKnownPosition();
      if (conocida != null && DateTime.now().difference(conocida.timestamp) < const Duration(minutes: 2)) {
        return conocida;
      }
    } catch (_) {}
    final DateTime limite = DateTime.now().add(_esperaPosicionInicial);
    while (_ultimaLectura == null && DateTime.now().isBefore(limite)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return _ultimaLectura;
  }

  /// La mejor lectura del precalentamiento se usa como punto de partida de la traza.
  void _sembrarPuntoInicial() {
    final Position? p = _ultimaLectura;
    if (p == null || p.accuracy > _precisionMaximaM) return;
    if (DateTime.now().difference(p.timestamp) > _vigenciaLectura) return;
    _registrarLectura(p);
  }

  // ============================================================
  // Sensado oportunista: captura y filtrado de la traza GPS
  // ============================================================
  void _iniciarCapturaGps() {
    _posicionSub?.cancel();
    _posicionSub = Geolocator.getPositionStream(locationSettings: ajustesGpsAltaPrecision()).listen(
      _procesarLectura,
      onError: (Object e) => debugPrint('Error GPS: $e'),
    );
  }

  void _procesarLectura(Position p) {
    _ultimaLectura = p;
    if (estado.value != 'grabando') return;
    _verificarProximidad(p);
    if (p.accuracy > _precisionMaximaM) return;
    _registrarLectura(p);
  }

  void _registrarLectura(Position p) {
    final DateTime ts = p.timestamp.toUtc();
    final ({double lat, double lon, DateTime ts})? ancla = _ancla;

    if (ancla != null) {
      if (!ts.isAfter(ancla.ts)) return; // lectura repetida o fuera de orden
      final double dCruda = Geolocator.distanceBetween(ancla.lat, ancla.lon, p.latitude, p.longitude);
      final double dt = ts.difference(ancla.ts).inMilliseconds / 1000;
      if (dCruda / dt > _velocidadMaximaMps && dCruda > p.accuracy * 2) return; // salto imposible
    }

    final ({double lat, double lon}) suave =
        _kalman.procesar(p.latitude, p.longitude, p.accuracy, ts.millisecondsSinceEpoch);

    if (ancla == null) {
      _aceptar(p, suave, ts, 0);
      return;
    }

    final double d = Geolocator.distanceBetween(ancla.lat, ancla.lon, suave.lat, suave.lon);
    final double umbral = math.max(_avanceMinimoM, p.accuracy * _factorPrecision);
    if (d >= umbral) {
      _aceptar(p, suave, ts, d);
    } else if (_ultimoGuardado == null || ts.difference(_ultimoGuardado!) >= _intervaloLatido) {
      // Quieto: se guarda un "latido" en el mismo punto (no suma distancia) para que el panel
      // no lo interprete como pérdida de señal.
      _guardarPunto(ancla.lat, ancla.lon, ts, p);
    }
  }

  void _aceptar(Position p, ({double lat, double lon}) suave, DateTime ts, double distanciaM) {
    distanciaKm.value += distanciaM / 1000;
    _ancla = (lat: suave.lat, lon: suave.lon, ts: ts);
    _guardarPunto(suave.lat, suave.lon, ts, p);
    _actualizarVelocidadPromedio();
  }

  void _guardarPunto(double lat, double lon, DateTime ts, Position p) {
    _bufferPuntos.add(PuntoGpsLocal(
      lat: lat,
      lon: lon,
      capturadoEn: ts,
      precisionM: p.accuracy,
      altitudM: p.altitude,
      velocidadMps: p.speed,
      iniciaTramo: _nuevoTramo,
    ));
    _nuevoTramo = false;
    _ultimoGuardado = ts;
  }

  // ============================================================
  // Sensado oportunista adicional: contador de pasos
  // ============================================================
  void _iniciarContadorPasos() {
    _pasosSub?.cancel();
    _pasosSub = Pedometer.stepCountStream.listen(
      _procesarPasos,
      onError: (Object e) {
        if (_reintentoPasos) {
          debugPrint('Error pedómetro: $e');
          return;
        }
        _reintentoPasos = true;
        _iniciarContadorPasos();
      },
    );
  }

  void _iniciarEstimadorPasos() {
    _aceleracionSub?.cancel();
    _aceleracionSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      _procesarAceleracion,
      onError: (Object e) => debugPrint('Acelerómetro no disponible: $e'),
    );
  }

  void _procesarAceleracion(AccelerometerEvent e) {
    final bool paso = _detector.procesar(e.x, e.y, e.z, DateTime.now());
    if (!paso || estado.value != 'grabando' || _contadorActivo) return;
    _pasosEstimados++;
    pasos.value = _pasosEstimados;
  }

  void _procesarPasos(StepCount evento) {
    // Si el contador no informó al suscribirse, los pasos ya estimados se asumen como reales
    _pasosBase ??= estado.value == 'grabando' ? evento.steps - _pasosEstimados : evento.steps;
    _ultimoConteo = evento.steps;
    if (estado.value != 'grabando') return;

    final int reales = math.max(evento.steps - _pasosBase! - _pasosEnPausa, 0);
    if (reales > 0 && !_contadorActivo) {
      _contadorActivo = true;            // desde aquí manda el contador exacto
      _aceleracionSub?.cancel();
      _aceleracionSub = null;
    }
    if (_contadorActivo) pasos.value = reales;
  }

  // ============================================================
  // Indicadores en vivo
  // ============================================================
  void _iniciarTemporizador() {
    _timerDuracion?.cancel();
    _actualizarDuracion();
    _timerDuracion = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarDuracion());
  }

  /// Se calcula con el reloj real: no acumula desfase aunque un tick se retrase.
  void _actualizarDuracion() {
    final DateTime? inicio = _inicioLocal;
    if (inicio == null || estado.value != 'grabando') return;
    duracionSegundos.value = math.max(DateTime.now().difference(inicio).inSeconds - _segundosPausados, 0);
    _actualizarVelocidadPromedio();
  }

  void _actualizarVelocidadPromedio() {
    if (duracionSegundos.value > 0) {
      velocidadPromedioKmh.value = distanciaKm.value / (duracionSegundos.value / 3600);
    }
  }

  // ============================================================
  // Envío periódico de lotes al backend
  // ============================================================
  void _iniciarEnvioPeriodico() {
    _timerEnvioLotes?.cancel();
    _timerEnvioLotes = Timer.periodic(intervaloEnvio, (_) => _enviarLoteActual());
  }

  Future<void> _enviarLoteActual() async {
    if (_bufferPuntos.isEmpty || sesion.value == null) return;
    final List<PuntoGpsLocal> lote = List<PuntoGpsLocal>.from(_bufferPuntos);
    _bufferPuntos.clear();
    try {
      await _repository.enviarPuntos(sesion.value!.id, lote);
    } catch (e) {
      _bufferPuntos.insertAll(0, lote); // reintenta en el siguiente ciclo
    }
  }

  // ============================================================
  // Pausa / reanudación / fin
  // ============================================================
  Future<void> pausarRecorrido() async {
    if (sesion.value == null || estado.value != 'grabando') return;
    await _enviarLoteActual();
    try {
      await _repository.pausarSesion(sesion.value!.id);
      estado.value = 'pausada';
      _momentoPausa = DateTime.now();
      _conteoAlPausar = _ultimoConteo;
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
      if (_conteoAlPausar != null && _ultimoConteo != null) {
        _pasosEnPausa += _ultimoConteo! - _conteoAlPausar!;   // los pasos en pausa no cuentan
      }
      _conteoAlPausar = null;

      // Nuevo tramo: no se une el punto de la pausa con el de la reanudación
      _ancla = null;
      _kalman.reiniciar();
      _nuevoTramo = true;

      estado.value = 'grabando';
    } catch (e) {
      Get.snackbar('Error', 'No se pudo reanudar el recorrido.');
    }
  }

  Future<void> finalizarRecorrido() async {
    if (sesion.value == null) return;

    if (_momentoPausa != null) {
      _segundosPausados += DateTime.now().difference(_momentoPausa!).inSeconds;
      _momentoPausa = null;
    }

    await _enviarLoteActual();
    _detenerStreams();
    await WakelockPlus.disable();

    try {
      final SesionModel resultado = await _repository.finalizarSesion(
        sesion.value!.id,
        tiempoPausadoSegundos: _segundosPausados,
        pasos: pasos.value,
      );
      sesion.value = resultado;
      estado.value = 'finalizada';

      distanciaKm.value = resultado.distanciaKm;
      duracionSegundos.value = resultado.duracionSegundos;
      velocidadPromedioKmh.value = resultado.velocidadPromedioKmh;

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
    _posicionSub = null;
    _pasosSub?.cancel();
    _pasosSub = null;
    _timerDuracion?.cancel();
    _timerEnvioLotes?.cancel();
    _aceleracionSub?.cancel();
    _aceleracionSub = null;
  }

  String get duracionFormateada {
    final Duration d = Duration(seconds: duracionSegundos.value);
    final String h = d.inHours.toString().padLeft(2, '0');
    final String m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h == '00' ? '$m:$s' : '$h:$m:$s';
  }

  // Consulta al servidor, como máximo 1 vez por minuto, si hay incidencias recientes cerca.
  Future<void> _verificarProximidad(Position p) async {
    final DateTime ahora = DateTime.now();
    if (_ultimaConsultaProximidad != null && ahora.difference(_ultimaConsultaProximidad!) < intervaloProximidad) return;
    _ultimaConsultaProximidad = ahora;

    try {
      final n = await _notifRepository.verificarProximidad(p.latitude, p.longitude);
      if (n == null) return;

      HapticFeedback.heavyImpact();
      Get.snackbar(
        n.titulo, n.mensaje,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 10),
        backgroundColor: const Color(0xFFFFF4E5),
        colorText: const Color(0xFF7A3E00),
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316)),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        onTap: (_) => Get.toNamed('/detalle-notificacion', arguments: n.id),
      );

      if (Get.isRegistered<NotificacionesController>()) {
        Get.find<NotificacionesController>().cargar(silencioso: true);
      }
    } catch (_) {
      // un fallo de red no debe interrumpir la grabación del recorrido
    }
  }
}