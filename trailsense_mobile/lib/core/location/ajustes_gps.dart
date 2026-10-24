import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS de máxima precisión, 1 lectura por segundo y sin filtro de distancia.
/// Android: proveedor fusionado de Google (GPS + redes + sensores). iOS: perfil de actividad física.
LocationSettings ajustesGpsAltaPrecision() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: false,
      );
    case TargetPlatform.iOS:
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
      );
    default:
      return const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0);
  }
}