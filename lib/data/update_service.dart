import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../l10n.dart';

class UpdateInfo {
  final String version;
  final String notes;
  final String apkUrl;
  final int size;
  const UpdateInfo({required this.version, required this.notes, required this.apkUrl, required this.size});
}

/// Checks the GitHub releases of the Windows app and installs a newer version.
class UpdateService {
  static const String repo = 'a3nnn/A3N-IPTV';
  static const String apkName = 'A3N_IPTV_Player_Setup.exe';

  /// Already asked during this app start (so "Later" isn't shown again and again).
  static bool askedThisSession = false;

  /// Returns the newer version, or null if the app is up to date / offline.
  static Future<UpdateInfo?> check() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json', 'User-Agent': AppConfig.appName},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! Map) return null;
      final tag = (data['tag_name'] ?? '').toString().replaceFirst(RegExp(r'^v'), '');
      if (!isNewer(tag, AppConfig.version)) return null;
      final assets = data['assets'] is List ? data['assets'] as List : const [];
      for (final a in assets.whereType<Map>()) {
        if (a['name'] == apkName && a['browser_download_url'] is String) {
          return UpdateInfo(
            version: tag,
            notes: (data['body'] ?? '').toString().trim(),
            apkUrl: a['browser_download_url'] as String,
            size: (a['size'] is int) ? a['size'] as int : 0,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  static bool isNewer(String remote, String local) {
    List<int> parts(String v) => v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final r = parts(remote), l = parts(local);
    for (var i = 0; i < 3; i++) {
      final a = i < r.length ? r[i] : 0;
      final b = i < l.length ? l[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }

  /// Downloads the APK, reporting progress 0..1 (or -1 if the size is unknown).
  static Future<File> download(UpdateInfo info, void Function(double progress) onProgress) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}\\A3N_IPTV_Player_Setup_${info.version}.exe');
    if (await file.exists()) await file.delete();

    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(info.apkUrl)));
      if (res.statusCode != 200) throw Exception('Download failed (${res.statusCode})');
      final total = res.contentLength ?? info.size;
      var received = 0;
      final sink = file.openWrite();
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(total > 0 ? received / total : -1);
      }
      await sink.close();
      return file;
    } finally {
      client.close();
    }
  }

  /// Runs the new installer (it updates over this version and opens the app
  /// again), then closes this app. Returns an error message if it can't start.
  static Future<String?> install(File setup) async {
    try {
      await Process.start(
        setup.path,
        const ['/SILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CLOSEAPPLICATIONS'],
        mode: ProcessStartMode.detached,
      );
    } catch (_) {
      return tr('Could not start the installer. Download it from GitHub instead.',
          'ما قدرنا نشغّل ملف التحديث. نزّله من قيت هب بدال كذا.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    exit(0);
  }
}
