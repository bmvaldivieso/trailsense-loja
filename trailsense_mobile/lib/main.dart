import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';

class LocalDevHttpOverrides extends HttpOverrides {
  final Uint8List certBytes;
  LocalDevHttpOverrides(this.certBytes);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final SecurityContext ctx = SecurityContext(withTrustedRoots: true);
    ctx.setTrustedCertificatesBytes(certBytes);
    return super.createHttpClient(ctx);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ScreenUtil.ensureScreenSize();

  await GetStorage.init();

  // Carga el certificado local antes de iniciar la app
  try {
    final data = await rootBundle.load('assets/certs/rootCA.pem');
    HttpOverrides.global = LocalDevHttpOverrides(data.buffer.asUint8List());
  } catch (e) {
    // ignore: avoid_print
    print('[WARN] No se pudo configurar el certificado global de desarrollo: $e');
  }

  runApp(const MyApp());
}