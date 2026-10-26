import 'package:flutter/material.dart';

import '../data/storage.dart';
import '../player/player_service.dart';
import '../utils.dart';
import '../l10n.dart';

/// Mute button + volume slider in a dark pill, for the video overlays.
class VolumeControl extends StatefulWidget {
  const VolumeControl({super.key});

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  final PlayerService _svc = PlayerService.instance;

  IconData _icon(double v) {
    if (v <= 0) return Icons.volume_off_rounded;
    if (v < 50) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _svc.player.stream.volume,
      initialData: _svc.player.state.volume,
      builder: (context, snap) {
        final v = (snap.data ?? 100).clamp(0.0, 100.0);
        return Container(
          height: 40,
          padding: const EdgeInsets.only(left: 4, right: 12),
          decoration: BoxDecoration(
            color: fade(Colors.black, 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: v <= 0 ? tr('Unmute (M)', 'إلغاء الكتم (M)') : tr('Mute (M)', 'كتم (M)'),
                iconSize: 22,
                color: Colors.white,
                onPressed: _svc.toggleMute,
                icon: Icon(_icon(v)),
              ),
              SizedBox(
                width: 110,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    inactiveTrackColor: fade(Colors.white, 0.25),
                  ),
                  child: Slider(
                    value: v,
                    min: 0,
                    max: 100,
                    onChanged: (x) => _svc.setVolume(x),
                    onChangeEnd: (x) => Storage.setVolume(x),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
