import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'data/disk_cache.dart';
import 'data/storage.dart';
import 'data/watch_history.dart';
import 'l10n.dart';
import 'screens/start_gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Storage.init();
  // The installed app's real version (same number as typed in release.bat).
  try {
    final info = await PackageInfo.fromPlatform();
    if (RegExp(r'^\d+\.\d+').hasMatch(info.version)) AppConfig.version = info.version;
  } catch (_) {}
  L.init();
  WatchHistory.init();
  // Saved posters / lists on this computer (doesn't hold up the start).
  DiskCache.init();

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
    // Changing the language redraws the whole app (new key = fresh screens).
    return ValueListenableBuilder<bool>(
      valueListenable: L.arabic,
      builder: (context, arabic, _) => MaterialApp(
        key: ValueKey(arabic),
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Arabic: the whole interface is laid out right-to-left.
        builder: (context, child) => Directionality(
          textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
        home: const StartGate(),
      ),
    );
  }
}
