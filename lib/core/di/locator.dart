import 'package:get_it/get_it.dart';
import 'package:stress_pilot/core/network/http_client.dart';
import 'package:stress_pilot/core/system/process_manager.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
import 'package:stress_pilot/features/projects/data/project_service.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/settings/data/setting_service.dart';
import 'package:stress_pilot/features/settings/presentation/provider/setting_provider.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton(() => CoreProcessManager());
  getIt.registerLazySingleton(() => ThemeManager());
  getIt.registerLazySingleton(() => HttpClient.getInstance());
  getIt.registerLazySingleton(() => ProjectService());
  getIt.registerLazySingleton(() => ProjectProvider());
  getIt.registerLazySingleton(() => SettingService());
  getIt.registerLazySingleton(() => SettingProvider());
}
