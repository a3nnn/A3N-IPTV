import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'data/storage.dart';
import 'screens/start_gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Storage.init();

  await windowManager.ensureInitialized();
  final options = WindowOptions(
    title: AppConfig.appName,
    size: const Size(1400, 820),
    minimumSize: const Size(1050, 640),
    center: true,
    backgroundColor: AppConfig.background,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const A3NApp());
}

class A3NApp extends StatelessWidget {
  const A3NApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const StartGate(),
    );
  }
}
