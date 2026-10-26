import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../config.dart';
import '../data/storage.dart';
import '../data/watch_history.dart';
import '../l10n.dart';
import '../player/player_service.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/stream_info.dart';
import '../widgets/sub_style.dart';

/// Full-window player for movies and series episodes (with seek bar).
/// Keys: Space play/pause, ◀ ▶ seek, F full screen, S audio & subtitles, Esc back.
class PlayerPage extends StatefulWidget {
  final String url;
  final String title;

  /// Movie / episode being watched (to remember where it stopped).
  final WatchEntry? watch;

  /// Jump here once the video is ready ("continue watching").
  final Duration startAt;
  const PlayerPage({super.key, required this.url, required this.title, this.watch, this.startAt = Duration.zero});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final PlayerService _svc = PlayerService.instance;
  Timer? _hideTimer;
  bool _showHeader = true;

  // Continue watching / saving the position.
  StreamSubscription<Duration>? _durSub;
  Timer? _saveTimer;
  bool _started = false; // the jump to [startAt] was done (or not needed)

  // Preferred subtitles (Settings), picked once when the file's tracks are known.
  StreamSubscription<Tracks>? _tracksSub;
  bool _subsPicked = false;

  void _pickSubtitles(Tracks tracks) {
    if (_subsPicked) return;
    final audio = tracks.audio.where((t) => t.id != 'auto' && t.id != 'no');
    final video = tracks.video.where((t) => t.id != 'auto' && t.id != 'no');
    if (audio.isEmpty && video.isEmpty) return; // file not opened yet
    _subsPicked = true;
    _tracksSub?.cancel();
    final pref = Storage.subtitleLang;
    final subs = tracks.subtitle.where((t) => t.id != 'auto' && t.id != 'no').toList();
    if (pref == 'off') {
      _svc.player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    bool isLang(SubtitleTrack t, List<String> codes, List<String> words) {
      final l = (t.language ?? '').toLowerCase().trim();
      final title = (t.title ?? '').toLowerCase();
      return codes.contains(l) || words.any((w) => title.contains(w) || l.contains(w));
    }
    bool ar(SubtitleTrack t) => isLang(t, const ['ar', 'ara', 'arb'], const ['arab', 'عرب']);
    bool en(SubtitleTrack t) => isLang(t, const ['en', 'eng'], const ['english']);
    SubtitleTrack? pick;
    for (final test in pref == 'en' ? [en] : (pref == 'ar_en' ? [ar, en] : [ar])) {
      for (final t in subs) {
        if (test(t)) {
          pick = t;
          break;
        }
      }
      if (pick != null) break;
    }
    if (pick != null) _svc.player.setSubtitleTrack(pick);
  }

  @override
  void initState() {
    super.initState();
    _started = widget.startAt <= Duration.zero;
    _svc.play(widget.url);
    _tracksSub = _svc.player.stream.tracks.listen(_pickSubtitles);
    if (!_started) {
      _durSub = _svc.player.stream.duration.listen((d) {
        if (d > Duration.zero) _jumpToStart();
      });
    }
    if (widget.watch != null) {
      _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _savePosition());
    }
    _poke();
  }

  Future<void> _jumpToStart() async {
    if (_started) return;
    _started = true;
    _durSub?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    try {
      await _svc.player.seek(widget.startAt);
    } catch (_) {}
  }

  void _savePosition() {
    final w = widget.watch;
    if (w == null || !_started) return;
    final st = _svc.player.state;
    final dur = st.duration.inSeconds;
    if (dur <= 0) return;
    WatchHistory.report(w, st.position.inSeconds, dur);
  }

  @override
  void dispose() {
    _savePosition();
    WatchHistory.saveNow();
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _durSub?.cancel();
    _tracksSub?.cancel();
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

  Future<void> _openTracks() async {
    _hideTimer?.cancel();
    await showDialog<void>(context: context, builder: (_) => _TracksDialog(player: _svc.player));
    if (mounted) _poke();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.goBack) {
            Navigator.of(context).maybePop();
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.keyS) {
            _openTracks();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          onHover: (_) => _poke(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Redrawn when the subtitle look is changed.
              ValueListenableBuilder<int>(
                valueListenable: SubStyle.changed,
                builder: (context, _, __) => Directionality(
                  // Seek bar and buttons always left → right.
                  textDirection: TextDirection.ltr,
                  child: Video(
                    controller: _svc.controller,
                    fill: Colors.black,
                    subtitleViewConfiguration: SubtitleViewConfiguration(
                      style: SubStyle.textStyle(),
                      padding: const EdgeInsets.fromLTRB(60, 0, 60, 90),
                    ),
                  ),
                ),
              ),
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
                        // Quality badge stays top-left in both languages.
                        textDirection: TextDirection.ltr,
                        children: [
                          StreamInfoBadge(show: _showHeader),
                          const SizedBox(width: 16),
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: tr('Back (Esc)', 'رجوع (Esc)'),
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
                          const SizedBox(width: 14),
                          RoundIconButton(
                            icon: Icons.subtitles_rounded,
                            tooltip: tr('Audio & subtitles (S)', 'الصوت والترجمة (S)'),
                            onTap: _openTracks,
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

// ------------------------------------------------------------ tracks menu

String _trackLabel(String id, String? title, String? language, int index) {
  final lang = (language ?? '').trim();
  final name = (title ?? '').trim();
  final parts = <String>[
    if (lang.isNotEmpty) lang.toUpperCase(),
    if (name.isNotEmpty && name.toLowerCase() != lang.toLowerCase()) name,
  ];
  return parts.isEmpty ? tr('Track ${index + 1}', 'مسار ${index + 1}') : parts.join('  ·  ');
}

class _TracksDialog extends StatefulWidget {
  final Player player;
  const _TracksDialog({required this.player});

  @override
  State<_TracksDialog> createState() => _TracksDialogState();
}

class _TracksDialogState extends State<_TracksDialog> {
  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final tracks = p.state.tracks;
    final current = p.state.track;
    final audio = tracks.audio.where((t) => t.id != 'auto' && t.id != 'no').toList();
    final subs = tracks.subtitle.where((t) => t.id != 'auto' && t.id != 'no').toList();

    Widget option({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      bool autofocus = false,
    }) {
      return FocusRing(
        radius: 8,
        child: ListTile(
        dense: true,
        autofocus: autofocus,
        selected: selected,
        selectedColor: AppConfig.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20),
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
      );
    }

    Widget column(String title, IconData icon, List<Widget> children) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: AppConfig.textSecondary),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 12, letterSpacing: L.spacing(1.3), color: AppConfig.textSecondary, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Flexible(child: ListView(shrinkWrap: true, children: children)),
            ],
          ),
        );

    final audioList = <Widget>[
      if (audio.isEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(tr('Only one audio track', 'يوجد مسار صوت واحد فقط'), style: const TextStyle(color: AppConfig.textSecondary)),
        ),
      for (var i = 0; i < audio.length; i++)
        option(
          label: _trackLabel(audio[i].id, audio[i].title, audio[i].language, i),
          selected: current.audio.id == audio[i].id,
          autofocus: current.audio.id == audio[i].id || (i == 0 && !audio.any((a) => a.id == current.audio.id)),
          onTap: () {
            p.setAudioTrack(audio[i]);
            Navigator.of(context).pop();
          },
        ),
    ];

    final subList = <Widget>[
      option(
        label: tr('Off', 'بدون ترجمة'),
        selected: current.subtitle.id == 'no' || !subs.any((s) => s.id == current.subtitle.id),
        autofocus: audio.isEmpty,
        onTap: () {
          p.setSubtitleTrack(SubtitleTrack.no());
          Navigator.of(context).pop();
        },
      ),
      for (var i = 0; i < subs.length; i++)
        option(
          label: _trackLabel(subs[i].id, subs[i].title, subs[i].language, i),
          selected: current.subtitle.id == subs[i].id,
          onTap: () {
            p.setSubtitleTrack(subs[i]);
            Navigator.of(context).pop();
          },
        ),
      if (subs.isEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(tr('No subtitles in this file', 'ما فيه ترجمة في هذا الملف'), style: const TextStyle(color: AppConfig.textSecondary)),
        ),
    ];

    return AlertDialog(
      backgroundColor: AppConfig.surface,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      content: SizedBox(
        width: 820,
        height: 360,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            column(tr('AUDIO', 'الصوت'), Icons.audiotrack_rounded, audioList),
            const SizedBox(width: 20),
            column(tr('SUBTITLES', 'الترجمة'), Icons.subtitles_rounded, subList),
            const SizedBox(width: 20),
            column(tr('SUBTITLE STYLE', 'شكل الترجمة'), Icons.format_color_text_rounded,
                const [SubStylePicker(compact: true)]),
          ],
        ),
      ),
    );
  }
}
