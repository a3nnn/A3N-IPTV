import 'package:flutter/material.dart';

import '../config.dart';
import '../data/storage.dart';
import '../data/xtream_api.dart';
import '../l10n.dart';
import '../player/player_service.dart';
import '../utils.dart';
import '../widgets/brand.dart';
import '../widgets/sub_style.dart';
import '../widgets/update_dialog.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  String _subLang = Storage.subtitleLang;

  void _setSubLang(String v) {
    setState(() => _subLang = v);
    Storage.setSubtitleLang(v);
  }

  Future<void> _setLanguage(bool arabic) async {
    if (arabic == L.isAr) return;
    await PlayerService.instance.stop();
    HomeScreen.openSettingsNext = true; // come back to this page
    await L.setArabic(arabic); // the whole app redraws in the new language
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.surface,
        title: Text(tr('Sign out?', 'تسجيل الخروج؟')),
        content: Text(tr('You will need to enter your username and password again.',
            'بتحتاج تكتب اسم المستخدم وكلمة المرور مرة ثانية.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel', 'إلغاء'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Sign out', 'تسجيل الخروج'))),
        ],
      ),
    );
    if (ok != true) return;
    await PlayerService.instance.stop();
    await Storage.clearCredentials();
    Session.api = null;
    Session.account = null;
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final acc = Session.account;
    final user = acc?.username.isNotEmpty == true ? acc!.username : (Storage.username ?? '-');

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text(tr('Settings', 'الإعدادات'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        _Card(
          title: tr('Language', 'اللغة'),
          children: [
            _Option(label: 'العربية', selected: L.isAr, onTap: () => _setLanguage(true)),
            _Option(label: 'English', selected: !L.isAr, onTap: () => _setLanguage(false)),
          ],
        ),
        const SizedBox(height: 20),
        _Card(
          title: tr('Account', 'الحساب'),
          children: [
            _InfoRow(tr('Username', 'اسم المستخدم'), user),
            _InfoRow(tr('Status', 'الحالة'), acc?.status.isNotEmpty == true ? acc!.status : '-'),
            _InfoRow(tr('Expires', 'ينتهي'),
                acc?.expDate != null ? fmtDate(acc!.expDate!) : tr('Unlimited', 'غير محدود')),
            if (acc != null && acc.maxConnections > 0)
              _InfoRow(tr('Connections', 'الاتصالات'), '${acc.activeConnections} / ${acc.maxConnections}'),
            _InfoRow(tr('Device ID', 'رقم الجهاز'), Storage.deviceId),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, color: AppConfig.danger),
                label: Text(tr('Sign out', 'تسجيل الخروج'), style: const TextStyle(color: AppConfig.danger)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppConfig.danger)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Card(
          title: tr('Subtitles for movies & series', 'ترجمة الأفلام والمسلسلات'),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                tr('Chosen automatically when a movie or episode starts (if the file has it).',
                    'تنختار تلقائياً أول ما يبدأ الفلم أو الحلقة (إذا كانت موجودة في الملف).'),
                style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
              ),
            ),
            for (final o in [
              ('off', tr('No subtitles', 'بدون ترجمة')),
              ('ar', tr('Arabic', 'العربية')),
              ('en', tr('English', 'الإنجليزية')),
              ('ar_en', tr('Arabic, otherwise English', 'العربية، وإذا ما فيه فالإنجليزية')),
            ])
              _Option(label: o.$2, selected: _subLang == o.$1, onTap: () => _setSubLang(o.$1)),
            const Divider(height: 28),
            Text(tr('Subtitle style', 'شكل الترجمة'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const SubStylePicker(),
          ],
        ),
        const SizedBox(height: 20),
        _Card(
          title: tr('Keyboard shortcuts', 'اختصارات الكيبورد'),
          children: [
            _InfoRow(tr('Live TV: full screen', 'البث: ملء الشاشة'),
                tr('Click the playing channel again, double-click the video, or F',
                    'اضغط على القناة الشغالة مرة ثانية، أو دبل كليك على الفيديو، أو F')),
            _InfoRow(tr('Live TV: change channel', 'البث: تغيير القناة'),
                tr('Arrow Up / Down, Page Up / Down', 'السهم فوق / تحت، Page Up / Down')),
            _InfoRow(tr('Volume', 'الصوت'), tr('Arrow Left / Right, mouse wheel, M = mute', 'السهم يمين / يسار، عجلة الماوس، M = كتم')),
            _InfoRow(tr('Movies & series', 'الأفلام والمسلسلات'),
                tr('Space = play / pause, Arrow Left / Right = seek, F = full screen, S = audio & subtitles',
                    'Space = تشغيل / إيقاف، السهم يمين / يسار = تقديم وترجيع، F = ملء الشاشة، S = الصوت والترجمة')),
            _InfoRow(tr('Back / exit full screen', 'رجوع / الخروج من ملء الشاشة'), 'Esc'),
          ],
        ),
        const SizedBox(height: 20),
        _Card(
          title: tr('About', 'عن التطبيق'),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Align(alignment: AlignmentDirectional.centerStart, child: BrandMark(size: 34)),
            ),
            _InfoRow(tr('Version', 'الإصدار'), AppConfig.version),
            const _InfoRow('', AppConfig.signature),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: () => checkForUpdatesManually(context),
                icon: const Icon(Icons.system_update_rounded),
                label: Text(tr('Check for updates', 'البحث عن تحديث')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 760),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConfig.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12, letterSpacing: L.spacing(1.3), color: AppConfig.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Option({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      selectedColor: AppConfig.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 190, child: Text(label, style: const TextStyle(color: AppConfig.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
