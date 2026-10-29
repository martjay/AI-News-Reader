import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/news_controller.dart';
import 'core/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(420, 560),
      title: '新闻',
      backgroundColor: Color(0xFF12151A),
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setTitle('新闻');
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final container = ProviderContainer();
  await container.read(settingsProvider.notifier).hydrate();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _Bootstrap(child: InkBriefApp()),
    ),
  );
}

class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap({required this.child});
  final Widget child;

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newsProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      ref.read(settingsProvider.notifier).touchVisit();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
