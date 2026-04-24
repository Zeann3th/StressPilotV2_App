# StressPilot UX Polish & Bug Fix Design

**Date:** 2026-04-24  
**Branch:** feat/fleet  
**Goal:** Fix P0 bugs, add 5 themes (JSON assets), full component audit + new design tokens (Zed baseline → Fleet polish), unify design system.

---

## P0 Bug Fixes

### 1. Upload File Broken (500 + FilePicker never opens)
**Root cause:** `_handleUpload` calls `getCapabilities()` before `FilePicker.pickFiles()`. If the capabilities endpoint returns 500, exception is thrown and file picker never opens.  
**Affected files:**
- `lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart`
- `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

**Fix:** Wrap `getCapabilities()` in try-catch. On failure, fallback to `['json', 'yaml', 'yml', 'proto']`. Always open picker regardless of capabilities result.

```dart
List<String> formats;
try {
  final caps = await getIt<UtilityRepository>().getCapabilities();
  formats = caps.parsers
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
```

Apply same pattern in both affected files.

---

### 2. API/Flow Dual Selection Bug
**Root cause:** `_EndpointList` checks `endpointProvider.selectedEndpoint` and `_FlowList` checks `flowProvider.selectedFlow` independently. Selecting a flow never clears endpoint selection (and vice versa), so both rows show as selected simultaneously.

**Affected files:**
- `lib/features/projects/presentation/widgets/workspace_sidebar.dart` (`_EndpointList.openTab`, `_FlowList.openTab`)

**Fix:** When opening an endpoint tab, call `flowProvider.selectFlow(null)`. When opening a flow tab, call `endpointProvider.selectEndpoint(null)`. Both providers need `selectEndpoint(null)` / `selectFlow(null)` to clear selection.

`EndpointProvider.selectEndpoint` takes non-nullable `Endpoint` — add `clearSelection()` that sets `_selectedEndpoint = null; notifyListeners();`. `FlowProvider.clearFlow()` already exists and sets `_selectedFlow = null`.

When opening endpoint tab: call `flowProvider.clearFlow()`.  
When opening flow tab: call `endpointProvider.clearSelection()`.

---

### 3. Agent Icon Duplicate at Top
**Root cause:** `WorkspaceNavBar` has a sparkles `_NavIconButton` (top-right). `StatusBar` has `_AgentToggle` (bottom-right). Two entry points for same action.  
**Affected files:**
- `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`

**Fix:** Remove sparkles `_NavIconButton` from `WorkspaceNavBar`. Remove `onToggleAgent` and `isAgentOpen` params from `WorkspaceNavBar`. Update `ProjectWorkspacePage` call site.

---

### 4. Tab Drag Handle "=" at Bottom
**Root cause:** `ReorderableListView.builder` defaults to `buildDefaultDragHandles: true` on desktop, rendering a `≡` drag handle indicator on each item.  
**Affected files:**
- `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`

**Fix:** Add `buildDefaultDragHandles: false` to `ReorderableListView.builder`.

---

### 5. Shift+Shift Search Dialog Left-Offset
**Root cause:** Dialog shown via global navigator overlay covers full window. `Alignment(0, -0.4)` centers on full width. With sidebar open (~260px), the dialog appears left of the content-area center.  
**Affected files:**
- `lib/core/input/global_shortcut_listener.dart`
- `lib/features/shared/presentation/provider/project_provider.dart`

**Fix:**
1. Add `bool isSidebarOpen` and `double sidebarWidth` to `ProjectProvider` (move from `_ProjectWorkspacePageState`).
2. In `_showGlobalSearch`, read `ProjectProvider.isSidebarOpen` and `sidebarWidth` via `getIt`.
3. Pass offset to `_GlobalSearchDialog` widget.
4. In `_GlobalSearchDialog`, add `Padding(left: isSidebarOpen ? sidebarWidth / 2 : 0)` to center dialog in content area.

---

## Design System Overhaul (Full Audit + New Tokens)

### Problem
60+ files use `AppColors.*` (hardcoded dark constants). 14+ files use `Theme.of(context).colorScheme.*`. `workspace_endpoints_list.dart` mixes both in the same widget. Light theme breaks because `AppColors.*` ignores theme state.

### Solution: ThemeContext Extension + Dynamic AppColors

**Step 1: `PilotColors` data class**
```dart
class PilotColors {
  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color divider;
  final Color activeItem;
  final Color hoverItem;
  final Color accent;
  final Color accentHover;
  final Color accentActive;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textMuted;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final Color methodGet;
  final Color methodPost;
  final Color methodPut;
  final Color methodDelete;
  final Color methodPatch;
}
```

**Step 2: `BuildContext` extension**
```dart
extension PilotThemeX on BuildContext {
  PilotColors get pc => Provider.of<ThemeManager>(this, listen: false).pilotColors;
}
```

**Step 3: `ThemeManager` exposes `PilotColors`**
Computed from `currentTheme.colors`, with fallback to dark constants. Notifies on theme change.

**Step 4: Audit all widgets**
Replace `AppColors.xyz` with `context.pc.xyz` in all presentation widgets. Keep `AppColors.*` constants only in:
- `ThemeManager` (theme setup)
- `PilotTheme` fallbacks
- Non-widget code (providers, repos)

**Step 5: Fix inconsistency in `workspace_endpoints_list.dart`**
Endpoint cards use `Theme.of(context).colorScheme.surface` for card bg. Replace with `context.pc.elevated` for consistency with sidebar.

---

## New Themes (JSON Assets)

### Approach: Bundled JSON in `assets/themes/`

Add to `pubspec.yaml`:
```yaml
assets:
  - assets/themes/
```

Load in `ThemeManager.loadAvailableThemes()` from assets bundle before checking filesystem. Themes load in order: built-in constants → bundled assets → user filesystem.

### Themes to Add

| ID | Name | Background | Accent |
|----|------|-----------|--------|
| `zed-dark` | Zed Dark | `#1a1a1a` | `#52a9ff` |
| `dracula` | Dracula | `#282a36` | `#bd93f9` |
| `nord` | Nord | `#2e3440` | `#88c0d0` |
| `one-dark` | One Dark Pro | `#282c34` | `#61afef` |
| `catppuccin-mocha` | Catppuccin Mocha | `#1e1e2e` | `#cba6f7` |

Each JSON file follows the existing `PilotTheme.fromJson` format:
```json
{
  "name": "Zed Dark",
  "brightness": "dark",
  "colors": {
    "background": "#1a1a1a",
    "surface": "#222222",
    "elevated": "#2a2a2a",
    "border": "#333333",
    "textPrimary": "#d4d4d4",
    "textSecondary": "#888888",
    "accent": "#52a9ff",
    "success": "#57a64a",
    "error": "#e06c75"
  }
}
```

---

## UI Polish: Zed Baseline → Fleet

### Tab Bar (`workspace_tab_bar.dart`)
- Height stays 36px
- Tab padding: `horizontal: 10` (tighter, Zed-like)
- File-type icon: color-coded (endpoint=link icon in blue, flow=gitFork in purple)
- Close button: `×` 12px, show on hover + active (already done, keep)
- Drag handles: removed (bug fix #4)
- Active indicator: 2px accent bottom border (already done, keep)
- No extra spacing between tabs

### Nav Bar (`workspace_nav_bar.dart`)
- Remove agent sparkles button (bug fix #3)
- Tighter button spacing: `4px` gaps instead of `6px`
- Use `flutter_animate` for hover state transitions (200ms fade)

### Sidebar (`workspace_sidebar.dart`)
- Row height: keep 32px but reduce horizontal padding from `sm-xs` to `xs`
- Section headers: smaller label text (10px, uppercase, letter-spacing 0.5)
- Search bar: height 28px (currently 40px toolbar)
- Upload + add buttons: 16px icons, 24px hit area

### Status Bar (`status_bar.dart`)
- Add project branch icon + name on left (after project name)
- Height: keep 22px
- Add theme name indicator in center (like Zed's mode indicator)

### Search Dialog (`global_shortcut_listener.dart`)
- Add `flutter_animate` fade+scale in animation (150ms)
- Centered correctly (bug fix #5)

### Endpoint Cards in Workspace (`workspace_endpoints_list.dart`)
- Use `context.pc.*` instead of `colorScheme.*` (consistency fix)
- Card border: `context.pc.border`
- Card bg: `context.pc.elevated`
- Text: `context.pc.textPrimary` / `context.pc.textSecondary`

### Component Audit Scope
All files in:
- `lib/features/projects/presentation/widgets/`
- `lib/features/shared/presentation/widgets/`
- `lib/features/agent/presentation/widgets/`
- `lib/features/endpoints/presentation/widgets/`
- `lib/features/environments/presentation/`
- `lib/features/settings/presentation/`

Action per file: replace `AppColors.xyz` → `context.pc.xyz` in `build()` methods. Keep static uses in `ThemeManager` and non-widget code.

---

## Architecture Summary

```
ThemeManager
  ├── PilotColors pilotColors (computed from currentTheme)
  ├── loadAvailableThemes() — built-ins + assets/themes/*.json + ~/.pilot/themes/*.json
  └── setTheme(id) — updates pilotColors, notifies listeners

BuildContext extension
  └── context.pc → PilotColors (via Provider.of<ThemeManager>)

Widgets
  └── use context.pc.xyz everywhere in build()
      (no more AppColors.xyz in presentation layer)

assets/themes/
  ├── zed-dark.json
  ├── dracula.json
  ├── nord.json
  ├── one-dark.json
  └── catppuccin-mocha.json
```

---

## Out of Scope
- Canvas/flow editor visual redesign
- Agent terminal styling
- New animation system beyond `flutter_animate` (already included)
- Results page redesign
- Marketplace page redesign
