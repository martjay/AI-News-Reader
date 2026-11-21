import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';
import 'settings.dart';

class DesktopTray with TrayListener, WindowListener {
  DesktopTray(this.readSettings);

  final AppSettings Function() readSettings;
  var _ready = false;
  var _quitting = false;

  bool get _desktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Future<void> start() async {
    if (!_desktop || _ready) return;
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    try {
      final icon = Platform.isWindows ? 'assets/icons/tray_icon.ico' : 'assets/icons/app_icon.png';
      await trayManager.setIcon(icon);
      trayManager.addListener(this);
      _ready = true;
      await applyMenu();
    } catch (e, st) {
      debugPrint('tray start failed: ${e.runtimeType}\n$st');
      windowManager.removeListener(this);
      _ready = false;
      await windowManager.setPreventClose(false);
    }
  }

  void dispose() {
    if (!_ready) return;
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _ready = false;
  }

  AppLocalizations get _l10n {
    final code = readSettings().language == 'en' ? 'en' : 'zh';
    return lookupAppLocalizations(Locale(code));
  }

  Future<void> applyMenu() async {
    if (!_ready) return;
    final l10n = _l10n;
    await trayManager.setToolTip(l10n.appTitle);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: l10n.trayShow, onClick: (_) => showWindow()),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: l10n.trayExit, onClick: (_) => quit()),
        ],
      ),
    );
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    try {
      await trayManager.destroy();
    } catch (e, st) {
      debugPrint('tray destroy failed: $e\n$st');
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    if (_quitting) return;
    if (_ready && readSettings().closeToTray) {
      windowManager.hide();
      return;
    }
    quit();
  }

  @override
  void onTrayIconMouseDown() {
    showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}
