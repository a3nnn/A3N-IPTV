import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../utils.dart';

/// "Made by A3N" — shown top-left on every screen.
class SignatureBadge extends StatelessWidget {
  const SignatureBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fade(AppConfig.primary, 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fade(AppConfig.primary, 0.55)),
      ),
      child: const Text(
        AppConfig.signature,
        style: TextStyle(
          color: AppConfig.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final IconData fallbackIcon;
  final int? cacheWidth;

  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.cacheWidth,
  });

  Widget _fallback() => Center(
        child: Icon(fallbackIcon, color: fade(AppConfig.textSecondary, 0.6), size: 22),
      );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty || !url.startsWith('http')) return _fallback();
    return Image.network(
      url,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }
}

class ChannelLogo extends StatelessWidget {
  final String url;
  final double size;
  const ChannelLogo({super.key, required this.url, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConfig.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: NetImage(url: url, fit: BoxFit.contain, fallbackIcon: Icons.tv_rounded, cacheWidth: 120),
    );
  }
}

class SelectableRow extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double height;

  const SelectableRow({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? fade(AppConfig.primary, 0.14) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: fade(AppConfig.textPrimary, 0.05),
        child: Container(
          height: height,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: selected ? AppConfig.primary : Colors.transparent, width: 3),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: selected ? AppConfig.textPrimary : fade(AppConfig.textPrimary, 0.88),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppConfig.primary),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class CountLabel extends StatelessWidget {
  final int count;
  const CountLabel(this.count, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text('$count', style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary)),
      );
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: fade(Colors.black, 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: size * 0.55),
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 46, color: AppConfig.textSecondary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppConfig.textSecondary)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class ClockText extends StatefulWidget {
  const ClockText({super.key});
  @override
  State<ClockText> createState() => _ClockTextState();
}

class _ClockTextState extends State<ClockText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        fmtTime(DateTime.now()),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppConfig.textPrimary),
      );
}
