import 'dart:io';

import 'package:ai_news_reader/l10n/app_localizations.dart';
import 'package:ai_news_reader/ui/settings/settings_page.dart';
import 'package:ai_news_reader/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_core/news_core.dart';

void main() {
  test('catalog parses bundled yaml shape', () {
    const yaml = '''
snapshot:
  defaultUrl: ""
sources:
  - id: qbitai
    name: 量子位
    nameEn: QbitAI
    category: china
    access: direct
    type: rss
    url: https://www.qbitai.com/feed
    home: https://www.qbitai.com
    intervalMinutes: 15
''';
    final catalog = SourceCatalog.parse(yaml);
    expect(catalog.byId('qbitai')?.name, '量子位');
  });

  test('bundled source names are readable Chinese or Latin brands', () {
    final yaml = File('../config/sources.yaml').readAsStringSync();
    final catalog = SourceCatalog.parse(yaml);
    expect(catalog.byId('qbitai')?.name, '量子位');
    expect(catalog.byId('jiqizhixin')?.name, '机器之心');
    expect(catalog.byId('zhihu')?.name, '知乎热榜');
    expect(catalog.byId('weibo')?.name, '微博热搜');
    final han = RegExp(r'[\u4e00-\u9fff]');
    for (final source in catalog.sources) {
      expect(source.name.contains('\uFFFD'), isFalse, reason: source.id);
      if (han.hasMatch(source.name)) {
        expect(source.name.contains('?'), isFalse, reason: source.id);
      }
    }
  });

  testWidgets('settings keeps developer fields behind advanced', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsPage(palette: AppPalette.light)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('高级'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('快照仓库（owner/repo）'), findsNothing);
    expect(find.text('API Key（可选）'), findsNothing);
    await tester.tap(find.text('高级'));
    await tester.pumpAndSettle();
    expect(find.text('快照仓库（owner/repo）'), findsOneWidget);
    expect(find.text('API Key（可选）'), findsOneWidget);
  });
}
