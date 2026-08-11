import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ScreenUtil.ensureScreenSize();

  await GetStorage.init();

  runApp(const MyApp());
}