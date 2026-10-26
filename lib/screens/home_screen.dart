import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../config.dart';
import '../data/license_service.dart';
import '../data/storage.dart';
import '../data/xtream_api.dart';
import '../player/player_service.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'blocked_screen.dart';
import 'catalog_sections.dart';
import 'live_section.dart';
import 'settings_section.dart';
import 'start_menu.dart';
import '../data/update_service.dart';
import '../l10n.dart';
import '../widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  /// Set when the language changes, so the app reopens on Settings.
  static bool openSettingsNext = false;

  /// -1 = the start menu.
  static int takeStartIndex() {
    final i = openSettingsNext ? 3 : -1;
    openSettingsNext = false;
    return i;
  }

  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = HomeScreen.takeStartIndex();
  // One key per section so the live section keeps its state when it
  // switches between normal and full-window layouts.
  final List<GlobalKey> _keys = List.generate(4, (_) => GlobalKey());
  Timer? _licenseTimer;

  @override
  void initState() {
    super.initState();
    // Re-check every 10 minutes so a block takes effect while the app is open.
    _licenseTimer = Timer.periodic(const Duration(minutes: 10), (_) => _checkLicense());
    // Look for a newer version a few seconds after opening (optional update).
    Future.delayed(const Duration(seconds: 3), _checkUpdate);
  }

  Future<void> _checkUpdate() async {
    if (UpdateService.askedThisSession) return;
    UpdateService.askedThisSession = true;
    final info = await UpdateService.check();
    if (info == null || !mounted) return;
    if (PlayerService.instance.fullscreen.value) return; // don't interrupt full-screen TV
    await showUpdateDialog(context, info);
  }

  @override
  void dispose() {
    _licenseTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLicense() async {
    final s = await LicenseService.check(username: Storage.username ?? '');
    if (!s.blocked || !mounted) return;
    _licenseTimer?.cancel();
    final player = PlayerService.instance;
    await player.stop();
    if (player.fullscreen.value) {
      player.fullscreen.value = false;
      try {
        await windowManager.setFullScreen(false);
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => BlockedScreen(message: s.message)),
      (_) => false,
    );
  }

  void _go(int i) {
    if (i == _index) return;
    if (_index == 0) PlayerService.instance.stop();
    if (i >= 0) Storage.setLastSection(i);
    setState(() => _index = i);
  }

  Widget _section() {
    switch (_index) {
      case 0:
        return const LiveSection();
      case 1:
        return const MoviesSection();
      case 2:
        return const SeriesSection();
      default:
        return const SettingsSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PlayerService.instance.fullscreen,
      builder: (context, fullscreen, _) {
        if (_index < 0) {
          return Scaffold(
            body: Column(
              children: [
                const TopBar(),
                Expanded(child: StartMenu(onSelect: _go)),
              ],
            ),
          );
        }
        final section = KeyedSubtree(key: _keys[_index], child: _section());
        if (fullscreen) {
          return Scaffold(backgroundColor: Colors.black, body: section);
        }
        return Scaffold(
          body: Column(
            children: [
              const TopBar(),
              Expanded(
                child: Row(
                  children: [
                    NavRail(index: _index, onSelect: _go),
                    const VerticalDivider(width: 1),
                    Expanded(child: section),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TopBar extends StatelessWidget {
  final Widget? leading;
  final String? title;
  const TopBar({super.key, this.leading, this.title});

  @override
  Widget build(BuildContext context) {
    final exp = Session.account?.expDate;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppConfig.surface,
        border: Border(bottom: BorderSide(color: AppConfig.divider)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Expanded(
            child: Text(
              title ?? AppConfig.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConfig.textPrimary),
            ),
          ),
          if (exp != null) ...[
            const Icon(Icons.event_available_rounded, size: 16, color: AppConfig.textSecondary),
            const SizedBox(width: 6),
            Text(tr('Expires ${fmtDate(exp)}', 'ينتهي ${fmtDate(exp)}'), style: const TextStyle(fontSize: 13, color: AppConfig.textSecondary)),
            const SizedBox(width: 22),
          ],
          const ClockText(),
        ],
      ),
    );
  }
}

class NavRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const NavRail({super.key, required this.index, required this.onSelect});

  // index -1 = back to the start menu.
  static List<(int, IconData, String)> get _items => [
        (-1, Icons.home_rounded, tr('Home', 'الرئيسية')),
        (0, Icons.live_tv_rounded, tr('Live TV', 'البث المباشر')),
        (1, Icons.movie_rounded, tr('Movies', 'الأفلام')),
        (2, Icons.video_library_rounded, tr('Series', 'المسلسلات')),
        (3, Icons.settings_rounded, tr('Settings', 'الإعدادات')),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      color: AppConfig.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          for (final it in _items)
            _NavItem(
              icon: it.$2,
              label: it.$3,
              selected: it.$1 == index,
              onTap: () => onSelect(it.$1),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppConfig.primary : AppConfig.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: selected ? fade(AppConfig.primary, 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
