import 'package:get_it/get_it.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/core/system/settings_manager.dart';
import 'package:stress_pilot/core/system/app_state_manager.dart';
import 'package:stress_pilot/features/projects/domain/repositories/flow_repository.dart';
import 'package:stress_pilot/features/projects/data/repositories/flow_repository_impl.dart';
import 'package:stress_pilot/features/projects/domain/repositories/project_repository.dart';
import 'package:stress_pilot/features/projects/data/repositories/project_repository_impl.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/endpoints/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/workspace_tab_provider.dart';
import 'package:stress_pilot/features/settings/domain/repositories/setting_repository.dart';
import 'package:stress_pilot/features/settings/data/repositories/setting_repository_impl.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';
import 'package:stress_pilot/features/marketplace/domain/repositories/plugin_repository.dart';
import 'package:stress_pilot/features/marketplace/data/repositories/plugin_repository_impl.dart';
import 'package:stress_pilot/features/marketplace/domain/repositories/plugin_capability_repository.dart';
import 'package:stress_pilot/features/settings/presentation/provider/plugin_settings_provider.dart';
import 'package:stress_pilot/features/settings/domain/repositories/function_repository.dart';
import 'package:stress_pilot/features/settings/data/repositories/function_repository_impl.dart';
import 'package:stress_pilot/features/settings/presentation/provider/function_settings_provider.dart';
import 'package:stress_pilot/features/scheduling/domain/repositories/schedule_repository.dart';
import 'package:stress_pilot/features/scheduling/data/repositories/schedule_repository_impl.dart';
import 'package:stress_pilot/features/scheduling/presentation/provider/scheduling_provider.dart';
import 'package:stress_pilot/features/shared/domain/repositories/run_repository.dart';
import 'package:stress_pilot/features/marketplace/data/repositories/plugin_capability_repository_impl.dart';
import 'package:stress_pilot/features/shared/domain/repositories/utility_repository.dart';
import 'package:stress_pilot/features/shared/data/repositories/utility_repository_impl.dart';
import 'package:stress_pilot/core/input/keymap_provider.dart';

import 'package:stress_pilot/features/environments/domain/repositories/environment_repository.dart';
import 'package:stress_pilot/features/environments/data/repositories/environment_repository_impl.dart';
import 'package:stress_pilot/features/environments/presentation/provider/environment_provider.dart';
import 'package:stress_pilot/features/results/domain/repositories/results_repository.dart';
import 'package:stress_pilot/features/results/data/repositories/results_repository_impl.dart';
import 'package:stress_pilot/features/results/presentation/provider/results_provider.dart';
import 'package:stress_pilot/features/shared/data/repositories/run_repository_impl.dart';
import 'package:stress_pilot/features/shared/presentation/provider/run_provider.dart';
import 'package:stress_pilot/features/agent/presentation/provider/agent_provider.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton(() => ProcessManager());
  getIt.registerLazySingleton(() => ThemeManager());
  getIt.registerLazySingleton(() => AppStateManager());

  getIt.registerLazySingleton<UtilityRepository>(() => UtilityRepositoryImpl());

  getIt.registerLazySingleton(() => HttpClient.getInstance());
  getIt.registerLazySingleton(() => SessionManager(getIt()));
  HttpClient.getInstance(sessionManager: getIt<SessionManager>());

  getIt.registerLazySingleton<ProjectRepository>(() => ProjectRepositoryImpl());
  getIt.registerLazySingleton(() => ProjectProvider());

  getIt.registerLazySingleton<FlowRepository>(() => FlowRepositoryImpl());
  getIt.registerLazySingleton(() => FlowProvider());

  getIt.registerLazySingleton<SettingRepository>(() => SettingRepositoryImpl());
  getIt.registerLazySingleton(() => SettingProvider(getIt()));

  getIt.registerLazySingleton(() => SettingsManager());
  getIt.registerLazySingleton(() => KeymapProvider());

  getIt.registerLazySingleton(() => EndpointProvider());
  getIt.registerLazySingleton(() => WorkspaceTabProvider());

  getIt.registerLazySingleton(() => CanvasProvider());

  getIt.registerLazySingleton<EnvironmentRepository>(
      () => EnvironmentRepositoryImpl());
  getIt.registerLazySingleton(() => EnvironmentProvider(getIt()));

  getIt.registerLazySingleton<ResultsRepository>(
    () => ResultsRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(
    () => ResultsProvider(getIt(), getIt<FlowRepository>()),
  );

  getIt.registerLazySingleton<RunRepository>(() => RunRepositoryImpl());
  getIt.registerLazySingleton(() => RunProvider(getIt()));

  getIt.registerLazySingleton<PluginRepository>(() => PluginRepositoryImpl());
  getIt.registerLazySingleton(() => PluginSettingsProvider(getIt()));
  getIt.registerLazySingleton<FunctionRepository>(() => FunctionRepositoryImpl());
  getIt.registerLazySingleton(() => FunctionSettingsProvider(getIt()));
  getIt.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl());
  getIt.registerLazySingleton(() => SchedulingProvider(getIt()));
  getIt.registerLazySingleton<PluginCapabilityRepository>(
      () => PluginCapabilityRepositoryImpl());

  getIt.registerLazySingleton(() => AgentProvider());

  getIt<ResultsProvider>();
}
