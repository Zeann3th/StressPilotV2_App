import 'package:get_it/get_it.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/system/session_manager.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/features/projects/data/flow_service.dart';
import 'package:stress_pilot/features/projects/data/project_service.dart';
import 'package:stress_pilot/features/projects/presentation/provider/canvas_provider.dart';
import 'package:stress_pilot/features/common/presentation/provider/endpoint_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/flow_provider.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/data/setting_service.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton(() => CoreProcessManager());
  getIt.registerLazySingleton(() => ThemeManager());

  getIt.registerLazySingleton(() => HttpClient.getInstance());
  getIt.registerLazySingleton(() => SessionManager(getIt()));
  HttpClient.getInstance(sessionManager: getIt<SessionManager>());

  getIt.registerLazySingleton(() => ProjectService());
  getIt.registerLazySingleton(() => ProjectProvider());
  
  getIt.registerLazySingleton(() => FlowService());
  getIt.registerLazySingleton(() => FlowProvider());

  getIt.registerLazySingleton(() => SettingService());
  getIt.registerLazySingleton(() => SettingProvider());

  getIt.registerLazySingleton(() => EndpointProvider());

  getIt.registerLazySingleton(() => CanvasProvider());
}
