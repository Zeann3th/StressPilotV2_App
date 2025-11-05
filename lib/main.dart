import 'package:flutter/material.dart';
import 'package:stress_pilot/core/app_root.dart';
import 'package:stress_pilot/core/di/locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const AppRoot());
}
