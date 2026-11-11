import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  // Ensure Flutter engine bindings are initialized before calling native or async APIs
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system status bar and navigation bar styles for Android Light Theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DevOpsLearningApp());
}
