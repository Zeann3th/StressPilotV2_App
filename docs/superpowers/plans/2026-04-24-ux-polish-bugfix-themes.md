# StressPilot UX Polish, Bug Fixes & Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 5 P0 bugs, add dynamic `context.pc` theme system, bundle 5 new themes, and apply full Zed→Fleet design polish across all presentation widgets.

**Architecture:** Add `PilotColors` data class + `context.pc` BuildContext extension so all widgets can read theme-aware colors. ThemeManager computes `PilotColors` from the active theme and notifies listeners. Bundled JSON theme files in `assets/themes/` are loaded at startup alongside user-filesystem themes.

**Tech Stack:** Flutter, Provider, LucideIcons, Google Fonts (Inter), flutter_animate, shadcn_ui, bitsdojo_window, file_picker.

---

## Color Mapping Reference (AppColors → PilotColors)

Use this in every component audit task:

| Old | New |
|-----|-----|
| `AppColors.baseBackground` / `AppColors.background` | `pc.background` |
| `AppColors.sidebarBackground` / `AppColors.surface` | `pc.surface` |
| `AppColors.elevatedSurface` / `AppColors.elevated` | `pc.elevated` |
| `AppColors.activeItem` | `pc.activeItem` |
| `AppColors.hoverItem` | `pc.hoverItem` |
| `AppColors.accent` / `AppColors.accentColor` | `pc.accent` |
| `AppColors.accentHover` | `pc.accentHover` |
| `AppColors.accentActive` | `pc.accentActive` |
| `AppColors.border` / `AppColors.borderCol` | `pc.border` |
| `AppColors.divider` | `pc.divider` |
| `AppColors.textPrimary` / `AppColors.primary` | `pc.textPrimary` |
| `AppColors.textSecondary` / `AppColors.secondary` | `pc.textSecondary` |
| `AppColors.textDisabled` / `AppColors.textMuted` / `AppColors.muted` | `pc.textDisabled` |
| `AppColors.error` | `pc.error` |
| `AppColors.methodGet` / `AppColors.success` | `pc.methodGet` |
| `AppColors.methodPost` / `AppColors.info` | `pc.methodPost` |
| `AppColors.methodPut` / `AppColors.warning` | `pc.methodPut` |
| `AppColors.methodDelete` | `pc.methodDelete` |
| `AppColors.methodPatch` | `pc.methodPatch` |

Pattern for every `build()` method: add `final pc = context.pc;` as first line, then replace all `AppColors.*` with `pc.*` using the table above.

---

## Task 1: PilotColors data class

**Files:**
- Create: `lib/core/themes/pilot_colors.dart`

- [ ] **Step 1: Create PilotColors**

```dart
// lib/core/themes/pilot_colors.dart
import 'package:flutter/material.dart';

class PilotColors {
  final Color background;
  final Color surface;
  final Color elevated;
  final Color activeItem;
  final Color hoverItem;
  final Color accent;
  final Color accentHover;
  final Color accentActive;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color error;
  final Color methodGet;
  final Color methodPost;
  final Color methodPut;
  final Color methodDelete;
  final Color methodPatch;

  const PilotColors({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.activeItem,
    required this.hoverItem,
    required this.accent,
    required this.accentHover,
    required this.accentActive,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.error,
    required this.methodGet,
    required this.methodPost,
    required this.methodPut,
    required this.methodDelete,
    required this.methodPatch,
  });

  // Convenience aliases
  Color get textMuted => textDisabled;
  Color get success => methodGet;
  Color get warning => methodPut;
  Color get info => methodPost;
}
```

- [ ] **Step 2: Verify compile**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app
flutter analyze lib/core/themes/pilot_colors.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/themes/pilot_colors.dart
git commit -m "feat: add PilotColors data class for theme-aware colors"
```

---

## Task 2: ThemeManager — expose pilotColors + load from assets

**Files:**
- Modify: `lib/core/themes/theme_manager.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add `assets/themes/` to pubspec.yaml**

In `pubspec.yaml`, find the `assets:` section and add `- assets/themes/`:

```yaml
  assets:
    - assets/images/
    - assets/core/
    - assets/fonts/
    - assets/agent/
    - assets/themes/
```

- [ ] **Step 2: Create assets/themes directory**

```bash
mkdir -p /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app/assets/themes
touch /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app/assets/themes/.gitkeep
```

- [ ] **Step 3: Add pilotColors getter + asset loading to ThemeManager**

Open `lib/core/themes/theme_manager.dart`. Add `import 'package:flutter/services.dart';` and `import 'package:stress_pilot/core/themes/pilot_colors.dart';` at top.

Replace the `loadAvailableThemes()` method and add `pilotColors` getter:

```dart
// Add these imports at top of theme_manager.dart:
import 'package:flutter/services.dart';
import 'package:stress_pilot/core/themes/pilot_colors.dart';

// Add this getter inside ThemeManager class (after existing getters):
PilotColors get pilotColors => _buildPilotColors(currentTheme);

PilotColors _buildPilotColors(PilotTheme theme) {
  return PilotColors(
    background:   theme.getColor('background',   AppColors.baseBackground),
    surface:      theme.getColor('surface',      AppColors.sidebarBackground),
    elevated:     theme.getColor('elevated',     AppColors.elevatedSurface),
    activeItem:   theme.getColor('activeItem',   AppColors.activeItem),
    hoverItem:    theme.getColor('hoverItem',    AppColors.hoverItem),
    accent:       theme.getColor('accent',       AppColors.accent),
    accentHover:  theme.getColor('accentHover',  AppColors.accentHover),
    accentActive: theme.getColor('accentActive', AppColors.accentActive),
    border:       theme.getColor('border',       AppColors.border),
    divider:      theme.getColor('divider',      AppColors.divider),
    textPrimary:  theme.getColor('textPrimary',  AppColors.textPrimary),
    textSecondary:theme.getColor('textSecondary',AppColors.textSecondary),
    textDisabled: theme.getColor('textDisabled', AppColors.textDisabled),
    error:        theme.getColor('error',        AppColors.error),
    methodGet:    theme.getColor('success',      AppColors.methodGet),
    methodPost:   theme.getColor('info',         AppColors.methodPost),
    methodPut:    theme.getColor('warning',      AppColors.methodPut),
    methodDelete: theme.getColor('methodDelete', AppColors.methodDelete),
    methodPatch:  theme.getColor('methodPatch',  AppColors.methodPatch),
  );
}

// Replace loadAvailableThemes() with this:
Future<void> loadAvailableThemes() async {
  _availableThemes.clear();
  _availableThemes.add(_fleetTheme);
  _availableThemes.add(_fleetLightTheme);

  // Load bundled asset themes
  try {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = jsonDecode(manifestContent);
    final themeAssets = manifest.keys
        .where((k) => k.startsWith('assets/themes/') && k.endsWith('.json'))
        .toList();

    for (final assetPath in themeAssets) {
      try {
        final content = await rootBundle.loadString(assetPath);
        final json = jsonDecode(content);
        final id = p.basenameWithoutExtension(assetPath.split('/').last);
        _availableThemes.add(PilotTheme.fromJson(id, json));
      } catch (e) {
        AppLogger.warning('Failed to parse bundled theme $assetPath: $e');
      }
    }
  } catch (e) {
    AppLogger.warning('Failed to load bundled themes: $e');
  }

  // Load user filesystem themes
  try {
    final String home = Platform.environment['HOME'] ??
                        Platform.environment['USERPROFILE'] ??
                        '/';
    final themesDir = Directory(p.join(home, '.pilot', 'client', 'themes'));
    if (await themesDir.exists()) {
      final files = themesDir.listSync().where((e) => e is File && e.path.endsWith('.json'));
      for (var entity in files) {
        try {
          final file = entity as File;
          final content = await file.readAsString();
          final json = jsonDecode(content);
          final id = p.basenameWithoutExtension(file.path);
          _availableThemes.add(PilotTheme.fromJson(id, json));
        } catch (e) {
          AppLogger.warning('Failed to parse theme file ${entity.path}: $e');
        }
      }
    }
  } catch (e) {
    AppLogger.warning('Failed to load external themes: $e');
  }
  notifyListeners();
}
```

- [ ] **Step 4: Verify compile**

```bash
flutter analyze lib/core/themes/theme_manager.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/themes/theme_manager.dart pubspec.yaml assets/themes/.gitkeep
git commit -m "feat: add pilotColors getter and bundled asset theme loading to ThemeManager"
```

---

## Task 3: context.pc BuildContext extension

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`

- [ ] **Step 1: Add import and extension to theme_tokens.dart**

At the top of `lib/core/themes/theme_tokens.dart`, add:

```dart
import 'package:provider/provider.dart';
import 'package:stress_pilot/core/themes/pilot_colors.dart';
import 'package:stress_pilot/core/themes/theme_manager.dart';
```

At the bottom of `lib/core/themes/theme_tokens.dart`, add:

```dart
extension PilotThemeX on BuildContext {
  /// Returns theme-aware colors. Safe to call inside build() — the app root
  /// watches ThemeManager so all descendants rebuild on theme change.
  PilotColors get pc => Provider.of<ThemeManager>(this, listen: false).pilotColors;
}
```

- [ ] **Step 2: Verify no circular import**

```bash
flutter analyze lib/core/themes/theme_tokens.dart
```

Expected: no errors. (If circular import, move extension to a new file `lib/core/themes/theme_extensions.dart` and import it from `theme_tokens.dart`.)

- [ ] **Step 3: Commit**

```bash
git add lib/core/themes/theme_tokens.dart
git commit -m "feat: add context.pc BuildContext extension for theme-aware colors"
```

---

## Task 4: Bundled theme JSON files

**Files:**
- Create: `assets/themes/zed-dark.json`
- Create: `assets/themes/dracula.json`
- Create: `assets/themes/nord.json`
- Create: `assets/themes/one-dark.json`
- Create: `assets/themes/catppuccin-mocha.json`

- [ ] **Step 1: Create zed-dark.json**

```json
{
  "name": "Zed Dark",
  "brightness": "dark",
  "colors": {
    "background": "#1a1a1a",
    "surface": "#222222",
    "elevated": "#2a2a2a",
    "activeItem": "#1e3a5f",
    "hoverItem": "#2a2a2a",
    "accent": "#52a9ff",
    "accentHover": "#6bbdff",
    "accentActive": "#3d8cd4",
    "border": "#333333",
    "divider": "#2a2a2a",
    "textPrimary": "#d4d4d4",
    "textSecondary": "#888888",
    "textDisabled": "#555555",
    "success": "#57a64a",
    "info": "#4b8fd4",
    "warning": "#c8a84b",
    "error": "#e06c75",
    "methodDelete": "#c25151",
    "methodPatch": "#8b68d4"
  }
}
```

- [ ] **Step 2: Create dracula.json**

```json
{
  "name": "Dracula",
  "brightness": "dark",
  "colors": {
    "background": "#282a36",
    "surface": "#21222c",
    "elevated": "#313341",
    "activeItem": "#44475a",
    "hoverItem": "#383a4a",
    "accent": "#bd93f9",
    "accentHover": "#caa8fa",
    "accentActive": "#a87ef5",
    "border": "#44475a",
    "divider": "#383a4a",
    "textPrimary": "#f8f8f2",
    "textSecondary": "#6272a4",
    "textDisabled": "#44475a",
    "success": "#50fa7b",
    "info": "#8be9fd",
    "warning": "#f1fa8c",
    "error": "#ff5555",
    "methodDelete": "#ff5555",
    "methodPatch": "#bd93f9"
  }
}
```

- [ ] **Step 3: Create nord.json**

```json
{
  "name": "Nord",
  "brightness": "dark",
  "colors": {
    "background": "#2e3440",
    "surface": "#3b4252",
    "elevated": "#434c5e",
    "activeItem": "#4c566a",
    "hoverItem": "#434c5e",
    "accent": "#88c0d0",
    "accentHover": "#9ecfdf",
    "accentActive": "#7ab0c0",
    "border": "#4c566a",
    "divider": "#3b4252",
    "textPrimary": "#eceff4",
    "textSecondary": "#d8dee9",
    "textDisabled": "#4c566a",
    "success": "#a3be8c",
    "info": "#81a1c1",
    "warning": "#ebcb8b",
    "error": "#bf616a",
    "methodDelete": "#bf616a",
    "methodPatch": "#b48ead"
  }
}
```

- [ ] **Step 4: Create one-dark.json**

```json
{
  "name": "One Dark Pro",
  "brightness": "dark",
  "colors": {
    "background": "#282c34",
    "surface": "#21252b",
    "elevated": "#2c313a",
    "activeItem": "#2c313c",
    "hoverItem": "#2c313a",
    "accent": "#61afef",
    "accentHover": "#7abff5",
    "accentActive": "#4d9fe0",
    "border": "#3e4451",
    "divider": "#2c313a",
    "textPrimary": "#abb2bf",
    "textSecondary": "#5c6370",
    "textDisabled": "#3e4451",
    "success": "#98c379",
    "info": "#56b6c2",
    "warning": "#e5c07b",
    "error": "#e06c75",
    "methodDelete": "#e06c75",
    "methodPatch": "#c678dd"
  }
}
```

- [ ] **Step 5: Create catppuccin-mocha.json**

```json
{
  "name": "Catppuccin Mocha",
  "brightness": "dark",
  "colors": {
    "background": "#1e1e2e",
    "surface": "#181825",
    "elevated": "#313244",
    "activeItem": "#45475a",
    "hoverItem": "#313244",
    "accent": "#cba6f7",
    "accentHover": "#d5b8fa",
    "accentActive": "#b994ed",
    "border": "#45475a",
    "divider": "#313244",
    "textPrimary": "#cdd6f4",
    "textSecondary": "#6c7086",
    "textDisabled": "#45475a",
    "success": "#a6e3a1",
    "info": "#89dceb",
    "warning": "#f9e2af",
    "error": "#f38ba8",
    "methodDelete": "#f38ba8",
    "methodPatch": "#cba6f7"
  }
}
```

- [ ] **Step 6: Verify themes load**

```bash
flutter analyze lib/
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add assets/themes/
git commit -m "feat: add 5 bundled themes (Zed Dark, Dracula, Nord, One Dark, Catppuccin Mocha)"
```

---

## Task 5: EndpointProvider — add clearSelection()

**Files:**
- Modify: `lib/features/shared/presentation/provider/endpoint_provider.dart`

- [ ] **Step 1: Add clearSelection() method**

In `lib/features/shared/presentation/provider/endpoint_provider.dart`, find `void selectEndpoint(Endpoint endpoint)` (around line 52) and add `clearSelection()` immediately after:

```dart
void selectEndpoint(Endpoint endpoint) {
  _selectedEndpoint = endpoint;
  notifyListeners();
}

void clearSelection() {
  _selectedEndpoint = null;
  notifyListeners();
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/shared/presentation/provider/endpoint_provider.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/shared/presentation/provider/endpoint_provider.dart
git commit -m "feat: add clearSelection() to EndpointProvider"
```

---

## Task 6: Bug Fix — Upload (capabilities error blocks FilePicker)

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

- [ ] **Step 1: Fix _handleUpload in workspace_endpoints_list.dart**

Find `Future<void> _handleUpload(BuildContext context) async {` and replace its body:

```dart
Future<void> _handleUpload(BuildContext context) async {
  try {
    List<String> formats;
    try {
      final capabilities = await getIt<UtilityRepository>().getCapabilities();
      formats = capabilities.parsers
          .expand((p) => p.formats)
          .map((e) => e.toLowerCase().replaceAll('.', ''))
          .toSet()
          .toList();
      if (formats.isEmpty) formats = ['json', 'yaml', 'yml', 'proto'];
    } catch (_) {
      formats = ['json', 'yaml', 'yml', 'proto'];
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: formats,
    );

    final filePath = result?.files.firstOrNull?.path;
    if (filePath != null) {
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Uploading endpoints...')),
      );
      if (!context.mounted) return;
      await context.read<EndpointProvider>().uploadEndpointsFile(
        filePath: filePath,
        projectId: widget.projectId,
      );
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Endpoints uploaded successfully')),
      );
    }
  } catch (e) {
    AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
    );
  }
}
```

- [ ] **Step 2: Fix _handleUpload in workspace_sidebar.dart**

Find `Future<void> _handleUpload(BuildContext context) async {` in `_SidebarSectionState` and replace its body with the same pattern:

```dart
Future<void> _handleUpload(BuildContext context) async {
  try {
    List<String> formats;
    try {
      final capabilities = await getIt<UtilityRepository>().getCapabilities();
      formats = capabilities.parsers
          .expand((p) => p.formats)
          .map((e) => e.toLowerCase().replaceAll('.', ''))
          .toSet()
          .toList();
      if (formats.isEmpty) formats = ['json', 'yaml', 'yml', 'proto'];
    } catch (_) {
      formats = ['json', 'yaml', 'yml', 'proto'];
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: formats,
    );

    final filePath = result?.files.firstOrNull?.path;
    if (filePath != null) {
      if (!context.mounted) return;
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Uploading endpoints...')),
      );
      final selectedProject = context.read<ProjectProvider>().selectedProject;
      if (selectedProject == null) return;
      await context.read<EndpointProvider>().uploadEndpointsFile(
        filePath: filePath,
        projectId: selectedProject.id,
      );
      if (!context.mounted) return;
      AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Endpoints uploaded successfully')),
      );
    }
  } catch (e) {
    AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
    );
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart lib/features/projects/presentation/widgets/workspace_sidebar.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart lib/features/projects/presentation/widgets/workspace_sidebar.dart
git commit -m "fix: guard capabilities fetch with try-catch so FilePicker always opens on upload"
```

---

## Task 7: Bug Fix — Dual selection (API + Flow both highlighted)

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

- [ ] **Step 1: Clear cross-selection on endpoint open**

In `_EndpointList.build()`, find the `openTab` local function:

```dart
void openTab(Endpoint e) {
  endpointProvider.selectEndpoint(e);
  context.read<WorkspaceTabProvider>().openTab(...);
}
```

Replace with:

```dart
void openTab(Endpoint e) {
  endpointProvider.selectEndpoint(e);
  context.read<FlowProvider>().clearFlow();
  context.read<WorkspaceTabProvider>().openTab(
    WorkspaceTab(
      id: 'endpoint_${e.id}',
      name: e.name,
      type: WorkspaceTabType.endpoint,
      data: e,
    ),
  );
}
```

- [ ] **Step 2: Clear cross-selection on flow open**

In `_FlowList.build()`, find the `openTab` local function:

```dart
void openTab(flow_domain.Flow f) {
  flowProvider.selectFlow(f);
  context.read<WorkspaceTabProvider>().openTab(...);
}
```

Replace with:

```dart
void openTab(flow_domain.Flow f) {
  flowProvider.selectFlow(f);
  context.read<EndpointProvider>().clearSelection();
  context.read<WorkspaceTabProvider>().openTab(
    WorkspaceTab(
      id: 'flow_${f.id}',
      name: f.name,
      type: WorkspaceTabType.flow,
      data: f,
    ),
  );
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace_sidebar.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_sidebar.dart
git commit -m "fix: clear cross-provider selection so API and Flow rows don't both show selected"
```

---

## Task 8: Bug Fix — Remove duplicate agent icon from nav bar

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`

- [ ] **Step 1: Remove agent params from WorkspaceNavBar**

In `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`, change the constructor:

```dart
class WorkspaceNavBar extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final bool isSidebarOpen;

  const WorkspaceNavBar({
    super.key,
    required this.onToggleSidebar,
    required this.isSidebarOpen,
  });
```

- [ ] **Step 2: Remove agent button from WorkspaceNavBar.build()**

In the `Row` of right controls, delete these lines:

```dart
// DELETE these lines:
const SizedBox(width: 4),
_NavIconButton(
  icon: LucideIcons.sparkles,
  tooltip: 'Agent',
  onPressed: onToggleAgent,
  isActive: isAgentOpen,
),
```

- [ ] **Step 3: Update call site in project_workspace_page.dart**

Find `WorkspaceNavBar(` in `_ProjectWorkspacePageState.build()` and update:

```dart
WorkspaceNavBar(
  onToggleSidebar: _toggleSidebar,
  isSidebarOpen: _isSidebarOpen,
),
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace_nav_bar.dart lib/features/projects/presentation/pages/project_workspace_page.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_nav_bar.dart lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "fix: remove duplicate agent sparkles icon from nav bar, status bar is the single toggle"
```

---

## Task 9: Bug Fix — Tab drag handle "=" at bottom

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`

- [ ] **Step 1: Disable default drag handles**

In `WorkspaceTabBar.build()`, find `ReorderableListView.builder(` and add `buildDefaultDragHandles: false`:

```dart
ReorderableListView.builder(
  scrollDirection: Axis.horizontal,
  buildDefaultDragHandles: false,
  onReorder: tabProvider.reorderTabs,
  itemCount: tabs.length,
  itemBuilder: (context, index) {
    // ... existing code unchanged
  },
),
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace_tab_bar.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_tab_bar.dart
git commit -m "fix: disable ReorderableListView default drag handles to remove '=' artifact on tabs"
```

---

## Task 10: Bug Fix — Shift+Shift search dialog centered on content area

**Files:**
- Modify: `lib/features/shared/presentation/provider/project_provider.dart`
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Modify: `lib/core/input/global_shortcut_listener.dart`

- [ ] **Step 1: Add sidebar state to ProjectProvider**

In `lib/features/shared/presentation/provider/project_provider.dart`, add these fields and methods (after existing fields):

```dart
// Sidebar state — kept here so GlobalShortcutListener can read it via getIt
bool _isSidebarOpen = true;
double _sidebarWidth = 260;

bool get isSidebarOpen => _isSidebarOpen;
double get sidebarWidth => _sidebarWidth;

void setSidebarState({required bool isOpen, required double width}) {
  _isSidebarOpen = isOpen;
  _sidebarWidth = width;
  // No notifyListeners — callers don't need to react to this
}
```

- [ ] **Step 2: Sync sidebar state from workspace page**

In `lib/features/projects/presentation/pages/project_workspace_page.dart`, update `_toggleSidebar`:

```dart
void _toggleSidebar() {
  setState(() => _isSidebarOpen = !_isSidebarOpen);
  getIt<ProjectProvider>().setSidebarState(
    isOpen: _isSidebarOpen,
    width: _sidebarWidth,
  );
}
```

Also update the drag-resize handler inside `GestureDetector.onHorizontalDragUpdate`:

```dart
onHorizontalDragUpdate: (details) {
  setState(() {
    _sidebarWidth = (_sidebarWidth + details.delta.dx)
        .clamp(_minSidebarWidth, _maxSidebarWidth);
  });
  getIt<ProjectProvider>().setSidebarState(
    isOpen: _isSidebarOpen,
    width: _sidebarWidth,
  );
},
```

Also add at the top of `_ProjectWorkspacePageState` — add import if not already present:
```dart
import 'package:stress_pilot/core/di/locator.dart';
```

- [ ] **Step 3: Update _GlobalSearchDialog to accept offset**

In `lib/core/input/global_shortcut_listener.dart`, update `_showGlobalSearch`:

```dart
void _showGlobalSearch() {
  final ctx = AppNavigator.navigatorKey.currentContext;
  if (ctx == null) return;
  final projectProvider = getIt<ProjectProvider>();
  final sidebarOffset = projectProvider.isSidebarOpen
      ? projectProvider.sidebarWidth / 2
      : 0.0;
  showDialog<void>(
    context: ctx,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    builder: (_) => _GlobalSearchDialog(sidebarOffset: sidebarOffset),
  );
}
```

Update `_GlobalSearchDialog`:

```dart
class _GlobalSearchDialog extends StatelessWidget {
  final double sidebarOffset;
  const _GlobalSearchDialog({this.sidebarOffset = 0});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.4),
      child: Padding(
        padding: EdgeInsets.only(left: sidebarOffset),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 480),
            decoration: BoxDecoration(
              color: context.pc.elevated,
              borderRadius: AppRadius.br8,
              border: Border.all(color: context.pc.border),
              boxShadow: AppShadows.card,
            ),
            child: const GlobalSearchDropdown(),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add ProjectProvider import to global_shortcut_listener.dart if not present**

The import `import 'package:stress_pilot/features/shared/presentation/provider/project_provider.dart';` is already there (used for `sidebar.toggle` action). Confirm — no change needed.

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/features/shared/presentation/provider/project_provider.dart lib/features/projects/presentation/pages/project_workspace_page.dart lib/core/input/global_shortcut_listener.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/shared/presentation/provider/project_provider.dart lib/features/projects/presentation/pages/project_workspace_page.dart lib/core/input/global_shortcut_listener.dart
git commit -m "fix: center shift+shift search dialog on content area, not full window width"
```

---

## Task 11: Component Audit — Workspace Widgets

Apply the color mapping reference at the top of this plan to every file listed.  
Pattern: add `final pc = context.pc;` as first line of `build()`, replace all `AppColors.*` with `pc.*`.

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_command_bar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_flow_tabs.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_node_library.dart`
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`

**Special case for `workspace_endpoints_list.dart`:** The endpoint cards currently use `Theme.of(context).colorScheme.surface` for card background. Replace these with `pc.elevated` and `pc.border` for consistency with sidebar.

Find in `_buildEndpointCard`:
```dart
// OLD:
color: colors.surface,
border: Border.all(color: colors.outlineVariant),
```
Replace with:
```dart
// NEW:
color: pc.elevated,
border: Border.all(color: pc.border),
```

Find in `_buildEndpointItem` text styles using `colors.onSurface` / `colors.onSurfaceVariant`:
```dart
// OLD:
color: colors.onSurface,
// and
color: colors.onSurfaceVariant,
```
Replace with:
```dart
// NEW:
color: pc.textPrimary,
// and
color: pc.textSecondary,
```

Remove `final colors = Theme.of(context).colorScheme;` from `_WorkspaceEndpointsListState.build()` after replacing all uses.

- [ ] **Step 1: Migrate workspace_nav_bar.dart**

Replace all `AppColors.*` uses in build methods with `pc.*`. Add `final pc = context.pc;` at start of each `build()`.

- [ ] **Step 2: Migrate workspace_tab_bar.dart**

Replace all `AppColors.*` with `pc.*`. Add `final pc = context.pc;` at start of each `build()`.

- [ ] **Step 3: Migrate workspace_sidebar.dart**

Replace all `AppColors.*` with `pc.*`. Add `final pc = context.pc;` at start of each `build()`.

- [ ] **Step 4: Migrate workspace_endpoints_list.dart** (includes colorScheme fix above)

Replace `AppColors.*` and `colorScheme.*` with `pc.*` per the special case note.

- [ ] **Step 5: Migrate workspace_canvas.dart, workspace_command_bar.dart, workspace_flow_tabs.dart, workspace_node_library.dart, project_workspace_page.dart**

Apply standard pattern to each.

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/features/projects/presentation/
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/projects/presentation/
git commit -m "refactor: migrate workspace widgets to context.pc theme-aware colors"
```

---

## Task 12: Component Audit — Shared, Agent, Endpoints, Results, Settings Widgets

Apply same color mapping pattern as Task 11.

**Files:**
- `lib/features/shared/presentation/widgets/app_skeleton.dart`
- `lib/features/shared/presentation/widgets/app_topbar.dart`
- `lib/features/shared/presentation/widgets/bottom_panel_shell.dart`
- `lib/features/shared/presentation/widgets/create_endpoint_dialog.dart`
- `lib/features/shared/presentation/widgets/endpoint_editor.dart`
- `lib/features/shared/presentation/widgets/environment_dialog.dart`
- `lib/features/shared/presentation/widgets/fleet_page_bar.dart`
- `lib/features/shared/presentation/widgets/global_search_dropdown.dart`
- `lib/features/shared/presentation/widgets/navigation_item.dart`
- `lib/features/shared/presentation/widgets/status_bar.dart`
- `lib/features/agent/presentation/pages/agent_page.dart`
- `lib/features/agent/presentation/widgets/agent_header.dart`
- `lib/features/agent/presentation/widgets/agent_input_bar.dart`
- `lib/features/agent/presentation/widgets/agent_message_bubble.dart`
- `lib/features/agent/presentation/widgets/agent_tool_dialog.dart`
- `lib/features/environments/presentation/pages/environment_page.dart`
- `lib/features/environments/presentation/widgets/environment_table.dart`
- `lib/features/results/presentation/pages/results_page.dart`
- `lib/features/results/presentation/pages/recent_runs_page.dart`
- `lib/features/results/presentation/widgets/metrics_card.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/settings/presentation/widgets/app_about_section.dart`
- `lib/features/settings/presentation/widgets/function_settings_view.dart`
- `lib/features/settings/presentation/widgets/keymap_settings_table.dart`
- `lib/features/settings/presentation/widgets/plugin_settings_view.dart`
- `lib/features/settings/presentation/widgets/settings_row.dart`
- `lib/features/settings/presentation/widgets/settings_table.dart`
- `lib/features/marketplace/presentation/pages/marketplace_page.dart`
- `lib/features/marketplace/presentation/widgets/pilot_webview.dart`

**Special case for `endpoint_editor.dart`:** The beginning of each section sub-builder (like `_buildHeaders`, `_buildBody`, etc.) uses local variables `final border = AppColors.border; final textColor = AppColors.textPrimary; ...`. Replace these with `final pc = context.pc;` and use `pc.*` throughout.

- [ ] **Step 1: Migrate shared widgets** (app_skeleton, app_topbar, bottom_panel_shell, create_endpoint_dialog, endpoint_editor, environment_dialog, fleet_page_bar, global_search_dropdown, navigation_item, status_bar)

- [ ] **Step 2: Migrate agent widgets**

- [ ] **Step 3: Migrate environments, results, settings, marketplace widgets**

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/
git commit -m "refactor: migrate all remaining widgets to context.pc theme-aware colors"
```

---

## Task 13: Design Polish — Tab Bar (Zed-style)

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`

- [ ] **Step 1: Tighten tab padding and polish styling**

In `_WorkspaceTabWidget.build()`, update the `AnimatedContainer`:

```dart
child: AnimatedContainer(
  duration: AppDurations.micro,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
  decoration: BoxDecoration(
    color: widget.isActive
        ? pc.activeItem
        : (_isHovered ? pc.hoverItem : Colors.transparent),
    border: Border(
      bottom: BorderSide(
        color: widget.isActive ? pc.accent : Colors.transparent,
        width: 2,
      ),
      right: BorderSide(color: pc.divider, width: 1),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(
        widget.tab.type == WorkspaceTabType.flow
            ? LucideIcons.gitFork
            : LucideIcons.link,
        size: 12,
        color: widget.isActive ? pc.accent : pc.textDisabled,
      ),
      const SizedBox(width: 5),
      // ... rest of children (text / edit field / close button)
    ],
  ),
),
```

- [ ] **Step 2: Shrink close button hit area for density**

Change the close button `SizedBox` fallback from `width: 12` to `width: 10`:

```dart
if ((_isHovered || widget.isActive) && !_isEditing)
  GestureDetector(
    onTap: widget.onClose,
    child: Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Icon(LucideIcons.x, size: 11, color: pc.textSecondary),
    ),
  )
else
  const SizedBox(width: 10),
```

- [ ] **Step 3: Remove rounded corners from tab (Zed is square)**

The existing `borderRadius` only applies top corners. Remove it entirely for a cleaner look:

```dart
// Remove:
borderRadius: const BorderRadius.only(
  topLeft: Radius.circular(4),
  topRight: Radius.circular(4),
),
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace_tab_bar.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_tab_bar.dart
git commit -m "design: Zed-style tab bar — tighter padding, square tabs, divider borders"
```

---

## Task 14: Design Polish — Sidebar density + section headers

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

- [ ] **Step 1: Shrink sidebar toolbar height and search bar**

In `WorkspaceSidebar.build()`, update the toolbar `Container`:

```dart
Container(
  height: 32,  // was 40
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
  // ...
)
```

- [ ] **Step 2: Update section header label style**

In `SidebarSectionHeader` (in `lib/features/shared/presentation/widgets/sidebar_section_header.dart`), update the label text style to be smaller and more Zed-like:

```dart
Text(
  label.toUpperCase(),
  style: AppTypography.label.copyWith(
    fontSize: 10,
    letterSpacing: 0.5,
    color: pc.textDisabled,
  ),
),
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace_sidebar.dart lib/features/shared/presentation/widgets/sidebar_section_header.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_sidebar.dart lib/features/shared/presentation/widgets/sidebar_section_header.dart
git commit -m "design: tighter sidebar toolbar height and smaller section header labels"
```

---

## Task 15: Design Polish — Search dialog fade+scale animation

**Files:**
- Modify: `lib/core/input/global_shortcut_listener.dart`

- [ ] **Step 1: Add flutter_animate import**

In `lib/core/input/global_shortcut_listener.dart`, add import:

```dart
import 'package:flutter_animate/flutter_animate.dart';
```

- [ ] **Step 2: Wrap dialog content with animation**

In `_GlobalSearchDialog.build()`, wrap the outermost `Material` with `.animate()`:

```dart
return Align(
  alignment: const Alignment(0, -0.4),
  child: Padding(
    padding: EdgeInsets.only(left: sidebarOffset),
    child: Material(
      color: Colors.transparent,
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: context.pc.elevated,
          borderRadius: AppRadius.br8,
          border: Border.all(color: context.pc.border),
          boxShadow: AppShadows.card,
        ),
        child: const GlobalSearchDropdown(),
      ),
    ).animate().fadeIn(duration: 120.ms).scaleXY(
      begin: 0.97,
      end: 1.0,
      duration: 150.ms,
      curve: Curves.easeOut,
    ),
  ),
);
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/core/input/global_shortcut_listener.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/input/global_shortcut_listener.dart
git commit -m "design: fade+scale animation on shift+shift search dialog open"
```

---

## Task 16: Design Polish — Status bar improvements

**Files:**
- Modify: `lib/features/shared/presentation/widgets/status_bar.dart`

- [ ] **Step 1: Add theme name indicator**

In `StatusBar.build()`, add a theme name chip in the center of the status bar. The `ThemeManager` is already in the provider tree.

```dart
@override
Widget build(BuildContext context) {
  final pc = context.pc;
  final themeManager = context.watch<ThemeManager>();

  return Container(
    height: 22,
    color: pc.surface,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Row(
      children: [
        if (projectName != null)
          Text(
            projectName!,
            style: AppTypography.caption.copyWith(color: pc.textSecondary, fontSize: 11),
          ),
        const Spacer(),
        // Theme indicator
        GestureDetector(
          onTap: themeManager.toggleTheme,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              themeManager.currentTheme.name,
              style: AppTypography.caption.copyWith(color: pc.textSecondary, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StatusIconButton(
          icon: LucideIcons.history,
          tooltip: 'Recent Runs',
          onTap: () => AppNavigator.pushNamed(AppRouter.recentRunsRoute),
        ),
        const SizedBox(width: 2),
        _AgentToggle(isOpen: isAgentOpen, onToggle: onAgentToggle),
      ],
    ),
  );
}
```

Add `import 'package:stress_pilot/core/themes/theme_manager.dart';` at top if not present.

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/shared/presentation/widgets/status_bar.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/shared/presentation/widgets/status_bar.dart
git commit -m "design: add theme name indicator to status bar with toggle on click"
```

---

## Task 17: Final verification build

- [ ] **Step 1: Full analyze**

```bash
flutter analyze lib/
```

Expected: no errors.

- [ ] **Step 2: Build debug**

```bash
flutter build linux --debug 2>&1 | tail -20
```

Expected: `✓ Built build/linux/x64/debug/bundle/stress_pilot`

- [ ] **Step 3: Smoke test**
  - Launch app: `flutter run -d linux`
  - Upload: click upload icon in sidebar → file picker opens (no 500 error)
  - Selection: click endpoint → highlighted. Click flow → only flow highlighted.
  - Agent: sparkles icon gone from top nav. Bottom status bar sparkles toggles panel.
  - Tabs: drag tabs to reorder — no "=" handle visible at bottom.
  - Shift+Shift: dialog appears centered on content area (not left-offset).
  - Themes: open Settings → theme selector shows 7 themes total (Fleet Dark, Fleet Light + 5 new).
  - Theme switch: switch to Zed Dark → all widgets update correctly.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: UX polish complete — 5 bugs fixed, 5 themes added, full design system audit"
```
