import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'routes/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(374, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TrailSense Loja',
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.routes,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
          ),
        );
      },
    );
  }
}