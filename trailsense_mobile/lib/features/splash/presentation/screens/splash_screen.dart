import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6),
      body: Center(
        child: Image.asset(
          'assets/animations/animacion_inicio.gif',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}