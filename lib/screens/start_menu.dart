import 'package:flutter/material.dart';

import '../config.dart';
import '../data/storage.dart';
import '../l10n.dart';
import '../utils.dart';

/// First screen: Live TV (wide) on top, then Series / Movies / Settings.
class StartMenu extends StatefulWidget {
  final ValueChanged<int> onSelect;
  const StartMenu({super.key, required this.onSelect});

  @override
  State<StartMenu> createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> {
  @override
  Widget build(BuildContext context) {
    final last = Storage.lastSection.clamp(0, 3);
    // Live TV on its own wide row; under it Series, Movies, Settings
    // (left → right in English, mirrored right → left in Arabic).
    final small = [
      (2, Icons.video_library_rounded, tr('Series', 'المسلسلات')),
      (1, Icons.movie_rounded, tr('Movies', 'الأفلام')),
      (3, Icons.settings_rounded, tr('Settings', 'الإعدادات')),
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MenuTile(
                icon: Icons.live_tv_rounded,
                label: tr('Live TV', 'البث المباشر'),
                height: 220,
                big: true,
                autofocus: last == 0,
                onTap: () => widget.onSelect(0),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < small.length; i++) ...[
                    if (i > 0) const SizedBox(width: 20),
                    Expanded(
                      child: _MenuTile(
                        icon: small[i].$2,
                        label: small[i].$3,
                        autofocus: last == small[i].$1,
                        onTap: () => widget.onSelect(small[i].$1),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool autofocus;
  final VoidCallback onTap;
  final double height;
  final bool big;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.autofocus = false,
    this.height = 160,
    this.big = false,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _focused && !widget.big ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: _focused ? fade(AppConfig.primary, 0.22) : AppConfig.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          autofocus: widget.autofocus,
          focusColor: Colors.transparent,
          onFocusChange: (f) => setState(() => _focused = f),
          onHover: (h) => setState(() => _focused = h),
          onTap: widget.onTap,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _focused ? AppConfig.primary : AppConfig.divider, width: _focused ? 3 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: widget.big ? 76 : 52, color: _focused ? AppConfig.primary : AppConfig.textPrimary),
                SizedBox(height: widget.big ? 18 : 14),
                Text(widget.label,
                    style: TextStyle(fontSize: widget.big ? 26 : 19, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
