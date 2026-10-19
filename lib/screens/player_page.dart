import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../player/player_service.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Full-window player for movies and series episodes (with seek bar).
class PlayerPage extends StatefulWidget {
  final String url;
  final String title;
  const PlayerPage({super.key, required this.url, required this.title});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final PlayerService _svc = PlayerService.instance;
  Timer? _hideTimer;
  bool _showHeader = true;

  @override
  void initState() {
    super.initState();
    _svc.play(widget.url);
    _poke();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _svc.stop();
    super.dispose();
  }

  void _poke() {
    _hideTimer?.cancel();
    if (!_showHeader) setState(() => _showHeader = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHeader = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack)) {
            Navigator.of(context).maybePop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          onHover: (_) => _poke(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(controller: _svc.controller, fill: Colors.black),
              StreamBuilder<bool>(
                stream: _svc.player.stream.buffering,
                initialData: _svc.player.state.buffering,
                builder: (context, snap) => snap.data == true
                    ? const IgnorePointer(child: Center(child: CircularProgressIndicator()))
                    : const SizedBox.shrink(),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showHeader ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: !_showHeader,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [fade(Colors.black, 0.75), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          const SignatureBadge(),
                          const SizedBox(width: 16),
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back (Esc)',
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
