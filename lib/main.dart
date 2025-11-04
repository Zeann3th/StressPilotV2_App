import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/di/locator.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/features/projects/presentation/pages/project_workspace_page.dart';
import 'package:stress_pilot/features/projects/presentation/pages/projects_page.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDependencies();

  final processManager = getIt<CoreProcessManager>();
  await processManager.start();

  final projectProvider = getIt<ProjectProvider>();
  await projectProvider.initialize();

  runApp(
    ChangeNotifierProvider<ProjectProvider>.value(
      value: projectProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    final Widget home = provider.hasSelectedProject
        ? const ProjectWorkspacePage()
        : const ProjectsPage();

    return MaterialApp(debugShowCheckedModeBanner: false, home: home);
  }
}
