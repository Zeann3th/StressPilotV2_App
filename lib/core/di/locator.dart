import 'package:get_it/get_it.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/config/settings_manager.dart';
import 'package:stress_pilot/features/projects/domain/repositories/flow_repository.dart';
import 'package:stress_pilot/features/projects/data/repositories/flow_repository_impl.dart';
import 'package:stress_pilot/features/projects/domain/repositories/project_repository.dart';
import 'package:stress_pilot/features/projects/data/repositories/project_repository_impl.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/data/setting_service.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/marketplace/data/plugin_service.dart';
import 'package:stress_pilot/features/marketplace/data/plugin_capability_service.dart';
import 'package:stress_pilot/features/common/data/utility_service.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';

import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/results/data/results_repository.dart';
import 'package:stress_pilot/features/results/data/run_service.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton(() => ProcessManager());
  getIt.registerLazySingleton(() => ThemeManager());

  getIt.registerLazySingleton(() => UtilityService());

  getIt.registerLazySingleton(() => HttpClient.getInstance());
  getIt.registerLazySingleton(() => SessionManager(getIt()));
  HttpClient.getInstance(sessionManager: getIt<SessionManager>());

  getIt.registerLazySingleton<ProjectRepository>(() => ProjectRepositoryImpl());
  getIt.registerLazySingleton(() => ProjectProvider());

  getIt.registerLazySingleton<FlowRepository>(() => FlowRepositoryImpl());
  getIt.registerLazySingleton(() => FlowProvider());

  getIt.registerLazySingleton(() => SettingService());
  getIt.registerLazySingleton(() => SettingProvider());
  
  getIt.registerLazySingleton(() => SettingsManager());
  getIt.registerLazySingleton(() => KeymapProvider());

  getIt.registerLazySingleton(() => EndpointProvider());

  getIt.registerLazySingleton(() => CanvasProvider());
  getIt.registerLazySingleton(() => EnvironmentProvider());

  getIt.registerLazySingleton(() => ResultsRepository());
  getIt.registerLazySingleton(
    () => ResultsProvider(getIt(), getIt<FlowRepository>()),
  );

  getIt.registerLazySingleton(() => RunService());

  getIt.registerLazySingleton(() => PluginService());
  getIt.registerLazySingleton(() => PluginCapabilityService());
  getIt<ResultsProvider>();
}
