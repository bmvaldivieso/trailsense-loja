import 'package:flutter/material.dart';
import 'app.dart';

import 'package:get_storage/get_storage.dart';

void main() async {
  // Asegura la inicialización de bindings de Flutter si vas a usar async en main
  WidgetsFlutterBinding.ensureInitialized();
  
  await GetStorage.init();

  runApp(const MyApp());
}