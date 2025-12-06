# Stress Pilot - AI Coding Agent Instructions

## Project Overview
Stress Pilot is a desktop Flutter application for load testing that integrates with a Java backend (JAR). The app manages the backend process lifecycle, maintains session state, and provides a visual flow-based interface for designing and executing load tests.

## Architecture

### Backend Integration Pattern
- **Process Management**: `CoreProcessManager` (`lib/core/system/process_manager.dart`) launches the Java backend (`assets/core/app.jar`) as a child process on app startup
- **Session Management**: `SessionManager` (`lib/core/system/session_manager.dart`) handles session lifecycle with health checks and automatic session refresh on 401 responses
- **Startup Sequence** (see `lib/core/app_root.dart`):
  1. Start JAR process via `CoreProcessManager.initialize()`
  2. Poll `/api/v1/utilities/healthz` endpoint (up to 24 attempts, 5s intervals)
  3. Initialize session via `/api/v1/utilities/session`
  4. Load projects via `ProjectProvider.initialize()`
  5. Display main UI only after full initialization

### Dependency Injection
- **GetIt** (`lib/core/di/locator.dart`): All services, providers, and managers are registered as lazy singletons
- Call `setupDependencies()` once at app startup in `main.dart`
- Access via `getIt<ServiceName>()` - never instantiate services/providers directly

### State Management
- **Provider Pattern**: All features use `ChangeNotifier` subclasses (e.g., `ProjectProvider`, `FlowProvider`, `EndpointProvider`)
- Providers are registered in GetIt as singletons and wrapped in `MultiProvider` in `app_root.dart`
- State persistence: `ProjectProvider` saves selected project to `SharedPreferences` with JSON serialization

### Feature Structure
Clean architecture with three layers per feature (see `lib/features/projects/`):
- **`data/`**: Service classes making HTTP calls via `HttpClient.getInstance()` (singleton `Dio` instance)
- **`domain/`**: Plain Dart models with `fromJson`/`toJson` methods
- **`presentation/`**: `pages/`, `widgets/`, and `provider/` subdirectories

### API Communication
- **Base URL**: `http://127.0.0.1:9760` (see `lib/core/config/app_config.dart`)
- **HTTP Client**: Singleton `Dio` instance (`lib/core/network/http_client.dart`) with:
  - Automatic cookie management via `CookieManager`
  - 401 interceptor that calls `SessionManager.initializeSession()` and retries requests
  - Standard timeouts: 10s connect, 10s receive
- **Paged Responses**: Use `PagedResponse<T>` wrapper (see `lib/core/models/paged_response.dart`) with factory method accepting item deserializer

## Critical Patterns

### Navigation
- **AppRouter** (`lib/core/navigation/app_router.dart`): Route generation via `generateRoute(RouteSettings)`
- **AppNavigator**: Static `GlobalKey<NavigatorState>` for navigation without context
- Navigate using `AppNavigator.navigatorKey.currentState?.pushNamed(route)`
- Route validation: Workspace route checks for selected project, redirects to projects page if null

### Logging
- **AppLogger** (`lib/core/system/logger.dart`): Centralized logging with levels (debug, info, warning, error, critical)
- Always specify `name` parameter: `AppLogger.info('message', name: 'ComponentName')`
- Use `AppLogger.measure()` for performance tracking of async operations
- Logs are only active in debug mode (`kDebugMode`)

### UI Framework
- **Fluent UI**: Primary UI framework (`fluent_ui` package) instead of Material
- Desktop-specific: Uses `bitsdojo_window` for custom window controls
- **Custom Fonts**: JetBrains Mono for code/monospace text (see `pubspec.yaml` fonts section)

## Development Workflows

### Running the App
```powershell
flutter run -d windows  # Desktop app
flutter pub get          # Install dependencies after pubspec.yaml changes
```

### Backend Requirements
- Java runtime must be available in PATH
- JAR file must exist at `assets/core/app.jar`
- Backend exposes API on port 9760

### Testing
- Test files in `test/` directory
- Run tests: `flutter test`

### Code Analysis
```powershell
flutter analyze  # Run static analysis
```

## Common Pitfalls

1. **Provider Access**: Always use `getIt<ProviderName>()` instead of `Provider.of<ProviderName>(context)` for non-UI logic
2. **Backend Startup**: Never make API calls before health check passes - app initialization handles this
3. **Session Expiry**: Don't manually handle 401s in services - `HttpClient` interceptor manages session refresh
4. **Model Serialization**: All domain models must implement `fromJson` and `toJson` for API compatibility
5. **Feature Isolation**: Keep feature code self-contained - cross-feature communication through providers only

## Key Files to Reference

- `lib/core/app_root.dart` - App initialization sequence and provider setup
- `lib/core/di/locator.dart` - Complete dependency graph
- `lib/core/network/http_client.dart` - HTTP interceptor logic and session handling
- `lib/features/projects/` - Reference implementation of clean architecture pattern
