import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

// 车联投屏（如 vivo Jovi InCar）的虚拟显示上，Flutter 收到的窗口尺寸为整屏，
// 但实际合成表面被车联 dock 裁掉一块，dock 以 viewPadding 上报。
// 此模式下按 viewPadding 裁剪根布局并清零安全区，避免二次留白与右侧/底部遮挡。
abstract final class CarWindow {
  static const _channel = MethodChannel(Constants.appName);

  static int _displayId = 0;
  static int _uiModeType = 0;
  static List<int>? _window;
  static List<int>? _max;
  static bool _debugShown = false;

  // Configuration.UI_MODE_TYPE_CAR == 3
  static bool get active =>
      Platform.isAndroid &&
      (Pref.carWindowFit || _displayId != 0 || _uiModeType == 3);

  static Future<void> init() async {
    await _query();
    WidgetsBinding.instance.addObserver(_MetricsObserver());
  }

  static Future<void> _query() async {
    try {
      final info = await _channel.invokeMethod<Map>('carWindowInfo');
      if (info == null) return;
      _displayId = info['displayId'] as int? ?? 0;
      _uiModeType = info['uiModeType'] as int? ?? 0;
      _window = (info['window'] as List?)?.cast<int>();
      _max = (info['max'] as List?)?.cast<int>();
    } catch (_) {}
  }

  static void debugToast(MediaQueryData mq) {
    if (!active || _debugShown) return;
    _debugShown = true;
    final text =
        '车联适配 display=$_displayId uiMode=$_uiModeType '
        'win=$_window max=$_max size=${mq.size} vp=${mq.viewPadding}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartDialog.showToast(text, displayTime: const Duration(seconds: 8));
    });
  }
}

class _MetricsObserver extends WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    CarWindow._query();
  }
}