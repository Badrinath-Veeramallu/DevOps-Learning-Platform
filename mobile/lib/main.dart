import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  // Ensure Flutter engine bindings are initialized before calling native or async APIs
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system status bar and navigation bar styles for Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090D16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DevOpsLearningApp());
}
