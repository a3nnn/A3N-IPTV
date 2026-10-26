import 'package:flutter/material.dart';

import '../config.dart';
import '../data/storage.dart';
import '../utils.dart';
import 'common.dart';
import '../l10n.dart';

class CategoryEntry {
  final String id;
  final String name;
  final int count;
  final IconData? icon;
  final Color? iconColor;

  /// Fixed entries (Favorites / All) stay on top and can't be pinned.
  final bool fixed;

  const CategoryEntry({
    required this.id,
    required this.name,
    required this.count,
    this.icon,
    this.iconColor,
    this.fixed = false,
  });
}

/// Category list with pinning. Pinned categories move to the top (under the
/// fixed entries) and are remembered per [section].
class CategoryPanel extends StatefulWidget {
  final String section;
  final List<CategoryEntry> entries;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const CategoryPanel({
    super.key,
    required this.section,
    required this.entries,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends State<CategoryPanel> {
  late List<String> _pinned = List.of(Storage.pinned(widget.section));
  String? _hoverId;

  void _togglePin(String id) {
    setState(() {
      if (!_pinned.remove(id)) _pinned.add(id);
    });
    Storage.setPinned(widget.section, _pinned);
  }

  @override
  Widget build(BuildContext context) {
    final fixed = widget.entries.where((e) => e.fixed).toList();
    final byId = {for (final e in widget.entries.where((e) => !e.fixed)) e.id: e};
    final pinned = [for (final id in _pinned) if (byId.containsKey(id)) byId[id]!];
    final rest = widget.entries.where((e) => !e.fixed && !_pinned.contains(e.id)).toList();

    final rows = <Widget>[
      for (final e in fixed) _row(e, pinned: false),
      if (pinned.isNotEmpty) _label(tr('PINNED', 'المثبتة')),
      for (final e in pinned) _row(e, pinned: true),
      if (pinned.isNotEmpty && rest.isNotEmpty) const Divider(height: 9, indent: 12, endIndent: 12),
      for (final e in rest) _row(e, pinned: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(tr('CATEGORIES', 'الأقسام'), top: 16),
        Expanded(child: ListView(children: rows)),
      ],
    );
  }

  Widget _label(String text, {double top = 10}) => Padding(
        padding: EdgeInsets.fromLTRB(16, top, 16, 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, letterSpacing: L.spacing(1.4), color: AppConfig.textSecondary, fontWeight: FontWeight.w700)),
      );

  Widget _row(CategoryEntry e, {required bool pinned}) {
    final hover = _hoverId == e.id;
    final showPin = !e.fixed && (pinned || hover);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverId = e.id),
      onExit: (_) => setState(() {
        if (_hoverId == e.id) _hoverId = null;
      }),
      child: SizedBox(
        height: 48,
        child: SelectableRow(
          selected: e.id == widget.selectedId,
          onTap: () => widget.onSelect(e.id),
          leading: e.icon != null
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Icon(e.icon, size: 18, color: e.iconColor ?? AppConfig.textSecondary),
                )
              : null,
          title: e.name,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CountLabel(e.count),
              if (!e.fixed)
                SizedBox(
                  width: 30,
                  child: showPin
                      ? IconButton(
                          tooltip: pinned ? tr('Unpin', 'إلغاء التثبيت') : tr('Pin to top', 'تثبيت فوق'),
                          padding: EdgeInsets.zero,
                          iconSize: 17,
                          onPressed: () => _togglePin(e.id),
                          icon: Icon(
                            pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            color: pinned ? AppConfig.primary : fade(AppConfig.textSecondary, 0.8),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
