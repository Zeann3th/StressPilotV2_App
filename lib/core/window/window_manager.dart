import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WindowSetup {
  static bool get isSupported =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows);

  static void initialize() {
    if (!isSupported) return;
    doWhenWindowReady(() {
      appWindow.minSize = const Size(800, 600);
      appWindow.size = const Size(1280, 800);
      appWindow.alignment = Alignment.center;
      appWindow.title = 'StressPilot';
      appWindow.show();
    });
  }
}
