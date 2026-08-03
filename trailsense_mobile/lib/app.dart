import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrailSense Loja',
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      // Puedes añadir el tema base aquí más adelante
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}