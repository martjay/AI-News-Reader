import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/news_controller.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';

const _authorQq = '398511660';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, required this.palette});

  final AppPalette palette;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _repo;
  late final TextEditingController _url;
  late final TextEditingController _apiKey;
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;
  late final TextEditingController _proxy;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _repo = TextEditingController(text: s.snapshotRepo);
    _url = TextEditingController(text: s.snapshotUrl);
    _apiKey = TextEditingController(text: s.translationApiKey);
    _baseUrl = TextEditingController(text: s.translationBaseUrl);
    _model = TextEditingController(text: s.translationModel);
    _proxy = TextEditingController(text: s.proxyUrl);
  }

  @override
  void dispose() {
    _repo.dispose();
    _url.dispose();
    _apiKey.dispose();
    _baseUrl.dispose();
    _model.dispose();
    _proxy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final p = widget.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s16, AppTokens.s16, AppTokens.s32),
      children: [
        Text(l10n.settingsSectionAppearance, style: AppType.section(p.fg)),
        const SizedBox(height: AppTokens.s12),
        _row(p, l10n.actionLanguage, SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'zh', label: Text(l10n.langZh)),
            ButtonSegment(value: 'en', label: Text(l10n.langEn)),
          ],
          selected: {settings.language},
          onSelectionChanged: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(language: v.first)),
        )),
        const SizedBox(height: AppTokens.s12),
        _row(p, l10n.actionTheme, SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'light', label: Text(l10n.themeLight)),
            ButtonSegment(value: 'dark', label: Text(l10n.themeDark)),
          ],
          selected: {settings.theme},
          onSelectionChanged: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(theme: v.first)),
        )),
        const SizedBox(height: AppTokens.s12),
        Text(l10n.fontSize, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        Slider(
          value: settings.fontScale,
          min: 0.9,
          max: 1.3,
          divisions: 4,
          activeColor: p.primary,
          onChanged: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(fontScale: v), persist: false),
          onChangeEnd: (v) => ref.read(settingsProvider.notifier).update(
                ref.read(settingsProvider).copyWith(fontScale: v),
              ),
        ),
        const SizedBox(height: AppTokens.s24),
        Text(l10n.settingsSectionNetwork, style: AppType.section(p.fg)),
        const SizedBox(height: AppTokens.s8),
        Text(l10n.proxyHint, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption, height: 1.5)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.useSystemProxy, style: TextStyle(color: p.fg, fontSize: AppTokens.body)),
          value: settings.useSystemProxy,
          activeThumbColor: p.primaryFg,
          activeTrackColor: p.primary,
          onChanged: (on) async {
            final next = settings.copyWith(useSystemProxy: on, proxyUrl: _proxy.text.trim());
            await ref.read(settingsProvider.notifier).update(next);
            await applyProxyFromSettings(next);
          },
        ),
        Text(l10n.proxyUrl, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        const SizedBox(height: AppTokens.s8),
        TextField(
          controller: _proxy,
          style: TextStyle(color: p.inputFg, fontSize: AppTokens.body),
          decoration: const InputDecoration(hintText: '127.0.0.1:7890'),
          onSubmitted: (_) => _saveProxy(settings),
        ),
        const SizedBox(height: AppTokens.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () async {
              await _saveProxy(settings);
              ref.read(newsProvider.notifier).refresh();
            },
            child: Text(l10n.done),
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        Text(l10n.settingsSectionTranslate, style: AppType.section(p.fg)),
        const SizedBox(height: AppTokens.s8),
        Text(l10n.translationHint, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption, height: 1.5)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.autoTranslate, style: TextStyle(color: p.fg, fontSize: AppTokens.body)),
          value: settings.autoTranslate,
          activeThumbColor: p.primaryFg,
          activeTrackColor: p.primary,
          onChanged: (on) {
            ref.read(settingsProvider.notifier).update(settings.copyWith(autoTranslate: on));
            if (on) ref.read(newsProvider.notifier).translatePending();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.showOriginal, style: TextStyle(color: p.fg, fontSize: AppTokens.body)),
          value: settings.showOriginal,
          activeThumbColor: p.primaryFg,
          activeTrackColor: p.primary,
          onChanged: (on) => ref.read(settingsProvider.notifier).update(settings.copyWith(showOriginal: on)),
        ),
        Text(l10n.translationApiKey, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        const SizedBox(height: AppTokens.s8),
        TextField(
          controller: _apiKey,
          obscureText: !_showApiKey,
          style: TextStyle(color: p.inputFg, fontSize: AppTokens.body),
          decoration: InputDecoration(
            hintText: 'sk-...',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showApiKey = !_showApiKey),
              icon: Icon(_showApiKey ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: p.fgMuted),
            ),
          ),
          onSubmitted: (v) => _saveTranslate(settings),
        ),
        const SizedBox(height: AppTokens.s12),
        Text(l10n.translationBaseUrl, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        const SizedBox(height: AppTokens.s8),
        TextField(
          controller: _baseUrl,
          style: TextStyle(color: p.inputFg, fontSize: AppTokens.body),
          decoration: const InputDecoration(hintText: 'https://api.deepseek.com/v1'),
          onSubmitted: (_) => _saveTranslate(settings),
        ),
        const SizedBox(height: AppTokens.s12),
        Text(l10n.translationModel, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        const SizedBox(height: AppTokens.s8),
        TextField(
          controller: _model,
          style: TextStyle(color: p.inputFg, fontSize: AppTokens.body),
          decoration: const InputDecoration(hintText: 'deepseek-chat'),
          onSubmitted: (_) => _saveTranslate(settings),
        ),
        const SizedBox(height: AppTokens.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () {
              _saveTranslate(settings);
              ref.read(newsProvider.notifier).translatePending();
            },
            child: Text(l10n.done),
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        Text(l10n.settingsSectionData, style: AppType.section(p.fg)),
        const SizedBox(height: AppTokens.s8),
        Text(l10n.snapshotHint, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption, height: 1.5)),
        const SizedBox(height: AppTokens.s12),
        Text(l10n.snapshotRepo, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        const SizedBox(height: AppTokens.s8),
        TextField(
          controller: _repo,
          style: TextStyle(color: p.inputFg, fontSize: AppTokens.body),
          decoration: const InputDecoration(hintText: 'owner/repo'),
          onSubmitted: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(snapshotRepo: v.trim())),
        ),
        const SizedBox(height: AppTokens.s12),
        Text(l10n.snapshotUrl, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        const SizedBox(height: AppTokens.s8),
        TextField(
          controller: _url,
          style: TextStyle(color: p.inputFg, fontSize: AppTokens.body),
          decoration: const InputDecoration(hintText: 'https://.../snapshot.json'),
          onSubmitted: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(snapshotUrl: v.trim())),
        ),
        const SizedBox(height: AppTokens.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).update(
                    settings.copyWith(snapshotRepo: _repo.text.trim(), snapshotUrl: _url.text.trim()),
                  );
              ref.read(newsProvider.notifier).refresh();
            },
            child: Text(l10n.done),
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        Text(l10n.aboutTitle, style: AppType.section(p.fg)),
        const SizedBox(height: AppTokens.s8),
        Text(l10n.aboutBody, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.body, height: 1.6)),
        const SizedBox(height: AppTokens.s12),
        _CopyAuthorRow(
          palette: p,
          label: l10n.authorQq,
          value: _authorQq,
          onTap: () => _copyAuthorQq(context),
        ),
      ],
    );
  }

  Future<void> _copyAuthorQq(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _authorQq));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).qqCopied), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _saveProxy(AppSettings settings) async {
    final next = settings.copyWith(proxyUrl: _proxy.text.trim());
    await ref.read(settingsProvider.notifier).update(next);
    await applyProxyFromSettings(next);
  }

  void _saveTranslate(AppSettings settings) {
    ref.read(settingsProvider.notifier).update(
          settings.copyWith(
            translationApiKey: _apiKey.text.trim(),
            translationBaseUrl: _baseUrl.text.trim().isEmpty ? 'https://api.deepseek.com/v1' : _baseUrl.text.trim(),
            translationModel: _model.text.trim().isEmpty ? 'deepseek-chat' : _model.text.trim(),
          ),
        );
  }

  Widget _row(AppPalette p, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.fgMuted, fontSize: AppTokens.caption)),
        const SizedBox(height: AppTokens.s8),
        child,
      ],
    );
  }
}

class _CopyAuthorRow extends StatefulWidget {
  const _CopyAuthorRow({
    required this.palette,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final AppPalette palette;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  State<_CopyAuthorRow> createState() => _CopyAuthorRowState();
}

class _CopyAuthorRowState extends State<_CopyAuthorRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final muted = _hover ? p.fg : p.fgMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
          child: Row(
            children: [
              Text(widget.label, style: TextStyle(color: muted, fontSize: AppTokens.body)),
              const SizedBox(width: AppTokens.s8),
              Text(widget.value, style: TextStyle(color: p.fg, fontSize: AppTokens.body, fontWeight: FontWeight.w600)),
              const SizedBox(width: AppTokens.s8),
              Icon(LucideIcons.copy, size: 14, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
