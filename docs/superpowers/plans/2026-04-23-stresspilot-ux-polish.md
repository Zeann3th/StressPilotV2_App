# StressPilot UX Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the top/status bar layout, unify icons to LucideIcons, add rounded corners and light theme, restore endpoint name editing and auto-beautify body, fix keymaps and add double-Shift global search, and add bitsdojo_window custom chrome.

**Architecture:**
- Top bar: Play + Env on left → center project picker → Marketplace + Settings on right (Agent removed from top bar).
- Status bar: project name left → Recent Runs icon + Agent icon-only on right.
- All Material `Icons.*` replaced with `LucideIcons.*` equivalents (lucide_icons already in pubspec).
- Light theme tokens added to theme_tokens.dart, ThemeManager switched to `ThemeMode.system` with manual override.
- `GlobalSearchDropdown` surfaced as an overlay triggered by double-Shift in `GlobalShortcutListener`.
- bitsdojo_window removes the OS title bar; traffic lights rendered inside `WorkspaceNavBar`.

**Tech Stack:** Flutter, Provider, LucideIcons, Google Fonts (Inter), bitsdojo_window, shadcn_ui.

---

### Task 1: NavBar Layout — Remove Agent, Move Buttons, Status Bar Runs + Agent

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`
- Modify: `lib/features/shared/presentation/widgets/status_bar.dart`

**Current layout (top bar):**
`[Play] [Env] | [Project (center)] | [Runs] [Market] [Settings] [Agent]`

**Target layout (top bar):**
`[Play] [Env] | [Project (center)] | [Market] [Settings]`

**Target status bar:**
`[project name] ————— [Runs icon] [Agent icon]`

- [ ] **Step 1: Remove Agent button from workspace_nav_bar.dart**

In `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`, remove the Agent `_NavIconButton` and the `SizedBox(width: 4)` before it. Remove `onAgentPressed` parameter and the `VoidCallback?` field. Remove the related import of `run_flow_dialog.dart` if it becomes unused.

```dart
// workspace_nav_bar.dart — class WorkspaceNavBar (no more onAgentPressed)
class WorkspaceNavBar extends StatelessWidget {
  const WorkspaceNavBar({super.key});
  // ...
}
```

Remove from the Row's right side:
```dart
// DELETE these two lines:
const SizedBox(width: 4),
_NavIconButton(
  icon: LucideIcons.sparkles,
  tooltip: 'Agent',
  onPressed: onAgentPressed ?? () => AppNavigator.pushNamed(AppRouter.agentRoute),
),
```

Also remove Recent Runs button from top bar (it moves to status bar):
```dart
// DELETE these two lines:
_NavIconButton(
  icon: LucideIcons.history,
  tooltip: 'Recent Runs',
  onPressed: () => AppNavigator.pushNamed(AppRouter.recentRunsRoute),
),
const SizedBox(width: 4),
```

- [ ] **Step 2: Update project_workspace_page.dart — remove onAgentPressed**

In `lib/features/projects/presentation/pages/project_workspace_page.dart`:

```dart
// Change this:
WorkspaceNavBar(onAgentPressed: _toggleAgent),
// To:
const WorkspaceNavBar(),
```

- [ ] **Step 3: Update StatusBar — add Recent Runs icon, make Agent icon-only**

Replace `lib/features/shared/presentation/widgets/status_bar.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/navigation/app_router.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class StatusBar extends StatelessWidget {
  final String? projectName;
  final bool isAgentOpen;
  final VoidCallback onAgentToggle;

  const StatusBar({
    super.key,
    this.projectName,
    required this.isAgentOpen,
    required this.onAgentToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          if (projectName != null)
            Text(
              projectName!,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          const Spacer(),
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
}

class _StatusIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _StatusIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_StatusIconButton> createState() => _StatusIconButtonState();
}

class _StatusIconButtonState extends State<_StatusIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(widget.icon, size: 12, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _AgentToggle extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  const _AgentToggle({required this.isOpen, required this.onToggle});

  @override
  State<_AgentToggle> createState() => _AgentToggleState();
}

class _AgentToggleState extends State<_AgentToggle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Agent',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: widget.isOpen
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : (_isHovered ? AppColors.hoverItem : Colors.transparent),
              borderRadius: AppRadius.br4,
            ),
            child: Icon(
              LucideIcons.sparkles,
              size: 12,
              color: widget.isOpen ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Analyze and commit**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace_nav_bar.dart \
  lib/features/shared/presentation/widgets/status_bar.dart \
  lib/features/projects/presentation/pages/project_workspace_page.dart
```

Expected: No issues found.

```bash
git add lib/features/projects/presentation/widgets/workspace_nav_bar.dart \
  lib/features/shared/presentation/widgets/status_bar.dart \
  lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "refactor: remove agent from top bar, move runs+agent icons to status bar"
```

---

### Task 2: Remove Canvas Run Button

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart`

- [ ] **Step 1: Delete `_RunButton` widget and its usage**

In `workspace_canvas.dart`, find and remove the `_RunButton` call from the toolbox row (around line 699):

```dart
// DELETE this line from the toolbox Row children:
_RunButton(onTap: () => _showRunDialog(context)),
```

Also delete the `_RunButton` class at the bottom of the file (around line 1729):

```dart
// DELETE the entire class:
class _RunButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RunButton({required this.onTap});
  // ...
}
```

- [ ] **Step 2: Analyze and commit**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart
```

Expected: No issues found.

```bash
git add lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart
git commit -m "feat: remove redundant run button from canvas toolbox"
```

---

### Task 3: Icon Pack Unification — Replace All Material Icons with LucideIcons

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart`
- Modify: `lib/features/projects/presentation/pages/recent_activity_page.dart`
- Modify: `lib/features/projects/presentation/widgets/subflow_configuration_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/node_configuration_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/run_flow_dialog.dart`

**Icon mapping (Material → LucideIcons):**

| Material | LucideIcons |
|---|---|
| `Icons.back_hand_rounded` | `LucideIcons.hand` |
| `Icons.edit_rounded` | `LucideIcons.pencil` |
| `Icons.lock_rounded` | `LucideIcons.lock` |
| `Icons.lock_open_rounded` | `LucideIcons.lockOpen` |
| `Icons.filter_center_focus_rounded` | `LucideIcons.crosshair` |
| `Icons.add_rounded` / `Icons.add` | `LucideIcons.plus` |
| `Icons.remove_rounded` | `LucideIcons.minus` |
| `Icons.code_rounded` | `LucideIcons.code` |
| `Icons.delete_sweep_outlined` | `LucideIcons.trash2` |
| `Icons.save_outlined` | `LucideIcons.save` |
| `Icons.play_arrow_rounded` | `LucideIcons.play` |
| `Icons.account_tree_outlined` / `Icons.account_tree_rounded` | `LucideIcons.network` |
| `Icons.call_split_rounded` | `LucideIcons.gitBranch` |
| `Icons.chevron_right_rounded` | `LucideIcons.chevronRight` |
| `Icons.format_align_left_rounded` | `LucideIcons.alignLeft` |
| `Icons.waves_rounded` | `LucideIcons.activity` |
| `Icons.route_rounded` | `LucideIcons.cornerDownRight` |
| `Icons.login_rounded` | `LucideIcons.logIn` |
| `Icons.logout_rounded` | `LucideIcons.logOut` |
| `Icons.upload_file` | `LucideIcons.upload` |
| `Icons.search` | `LucideIcons.search` |
| `Icons.open_in_new` | `LucideIcons.externalLink` |
| `Icons.info_outline` | `LucideIcons.info` |
| `Icons.close` | `LucideIcons.x` |
| `Icons.remove_circle_outline` | `LucideIcons.minusCircle` |
| `Icons.drag_indicator` | `LucideIcons.gripVertical` |

- [ ] **Step 1: Replace icons in workspace_canvas.dart**

Apply the mapping table. Every `Icons.` usage in this file must become `LucideIcons.`. Note: canvas toolbox items pass `IconData` to a helper function — update those call sites too.

Key replacements (file `lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart`):

```dart
// Line ~54: flow empty state icon
Icon(LucideIcons.network, ...) // was Icons.account_tree_outlined

// Toolbox mode buttons (~571, ~574):
_buildModeButton(provider, CanvasMode.move, LucideIcons.hand, 'Pan')
_buildModeButton(provider, CanvasMode.connect, LucideIcons.pencil, 'Link')

// Toolbox action icons (~586-674):
icon: provider.isLocked ? LucideIcons.lock : LucideIcons.lockOpen,
icon: LucideIcons.crosshair,  // center focus
icon: LucideIcons.plus,        // zoom in
icon: LucideIcons.minus,       // zoom out
icon: LucideIcons.code,        // connection style
icon: LucideIcons.trash2,      // clear
icon: LucideIcons.save,        // save

// Connection style icons (~787-789):
case ConnectionLineStyle.straight: return LucideIcons.minus;
case ConnectionLineStyle.curved: return LucideIcons.activity;
case ConnectionLineStyle.orthogonal: return LucideIcons.cornerDownRight;

// Node step icons (~1164, ~1169):
icon: LucideIcons.logIn,
icon: LucideIcons.logOut,

// Node card icon (~1223):
Icon(LucideIcons.network, ...)

// Node chevron (~1253):
Icon(LucideIcons.chevronRight, ...)

// Start node play icon (~1282):
Icon(LucideIcons.play, color: Colors.white, size: 24)

// Subflow split icon (~1328):
Icon(LucideIcons.gitBranch, ...)

// Format/align icon (~1570):
icon: LucideIcons.alignLeft,
```

Ensure `shadcn_ui` import is present (it re-exports LucideIcons). Remove `import 'package:flutter/material.dart'` only if nothing else from it is used — keep it since Flutter widgets need it.

- [ ] **Step 2: Replace icons in workspace_endpoints_list.dart**

File: `lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart`

```dart
// Replace:
icon: Icon(Icons.upload_file, size: 16, color: AppColors.textMuted),
// With:
icon: Icon(LucideIcons.upload, size: 16, color: AppColors.textMuted),

// Replace:
Icons.drag_indicator,
// With:
LucideIcons.gripVertical,
```

- [ ] **Step 3: Replace icons in recent_activity_page.dart**

File: `lib/features/projects/presentation/pages/recent_activity_page.dart` (~line 160):

```dart
// Replace:
const Icon(Icons.add, size: 14, color: Colors.white),
// With:
Icon(LucideIcons.plus, size: 14, color: Colors.white),
```

- [ ] **Step 4: Replace icons in subflow_configuration_dialog.dart**

File: `lib/features/projects/presentation/widgets/subflow_configuration_dialog.dart`:

```dart
// Replace:
prefixIcon: Icons.search,
// With:
prefixIcon: LucideIcons.search,

// Replace:
icon: Icons.open_in_new,
// With:
icon: LucideIcons.externalLink,
```

- [ ] **Step 5: Replace icons in node_configuration_dialog.dart**

File: `lib/features/projects/presentation/widgets/node_configuration_dialog.dart` (~line 224):

```dart
// Replace:
Icon(Icons.info_outline, size: 48, color: mutedTextColor),
// With:
Icon(LucideIcons.info, size: 48, color: mutedTextColor),
```

- [ ] **Step 6: Replace icons in run_flow_dialog.dart**

File: `lib/features/projects/presentation/widgets/run_flow_dialog.dart`:

```dart
// Replace (~line 223):
icon: const Icon(Icons.close, size: 18),
// With:
icon: const Icon(LucideIcons.x, size: 18),

// Replace (~line 237):
icon: Icons.add,
// With:
icon: LucideIcons.plus,

// Replace (~line 271):
icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
// With:
icon: const Icon(LucideIcons.minusCircle, color: AppColors.error, size: 20),
```

- [ ] **Step 7: Analyze entire lib/ and commit**

```bash
flutter analyze lib/
```

Expected: No issues found.

```bash
git add lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart \
  lib/features/projects/presentation/widgets/workspace/workspace_endpoints_list.dart \
  lib/features/projects/presentation/pages/recent_activity_page.dart \
  lib/features/projects/presentation/widgets/subflow_configuration_dialog.dart \
  lib/features/projects/presentation/widgets/node_configuration_dialog.dart \
  lib/features/projects/presentation/widgets/run_flow_dialog.dart
git commit -m "style: unify icon pack — replace all Material Icons with LucideIcons"
```

---

### Task 4: Rounded Corners + Light Theme

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`
- Modify: `lib/core/themes/theme_manager.dart`

- [ ] **Step 1: Bump AppRadius values in theme_tokens.dart**

```dart
abstract class AppRadius {
  static const r4  = Radius.circular(6);   // was 4 — buttons, inputs, chips
  static const r6  = Radius.circular(8);   // was 6 — panels, cards
  static const r8  = Radius.circular(12);  // was 8 — dialogs

  static const br4  = BorderRadius.all(r4);
  static const br6  = BorderRadius.all(r6);
  static const br8  = BorderRadius.all(r8);

  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
  static const br12 = BorderRadius.all(r12);
  static const br16 = BorderRadius.all(r16);
}
```

- [ ] **Step 2: Add light theme color set to theme_tokens.dart**

Add a `AppColorsLight` class below `AppColors`:

```dart
abstract class AppColorsLight {
  static const baseBackground    = Color(0xFFF5F5F5);
  static const sidebarBackground = Color(0xFFEBEBEB);
  static const elevatedSurface   = Color(0xFFFFFFFF);
  static const activeItem        = Color(0xFFDDDDE8);
  static const hoverItem         = Color(0xFFE8E8F0);
  static const accent            = Color(0xFF6B58D6); // slightly deeper for light bg
  static const accentHover       = Color(0xFF7B68EE);
  static const border            = Color(0x1F000000); // rgba(0,0,0,0.12)
  static const divider           = Color(0x14000000); // rgba(0,0,0,0.08)
  static const textPrimary       = Color(0xFF1A1A1A);
  static const textSecondary     = Color(0xFF555550);
  static const textDisabled      = Color(0xFFAAAAAA);
  static const accentActive      = Color(0xFF5A48C4);

  // Method badge colors same as dark
  static const methodGet    = Color(0xFF57A64A);
  static const methodPost   = Color(0xFF4B8FD4);
  static const methodPut    = Color(0xFFC8A84B);
  static const methodDelete = Color(0xFFC25151);
  static const methodPatch  = Color(0xFF8B68D4);
  static const error        = Color(0xFFD2504B);
  static const success      = methodGet;
  static const warning      = methodPut;
  static const info         = methodPost;
}
```

- [ ] **Step 3: Update ThemeManager to provide both themes**

Read current `lib/core/themes/theme_manager.dart` first, then update it to expose both dark and light `ThemeData`, and allow toggling. The manager must rebuild with `notifyListeners()` on toggle.

```dart
import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class ThemeManager extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.baseBackground,
    colorScheme: ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.sidebarBackground,
      error: AppColors.error,
    ),
    fontFamily: 'Inter',
    dividerColor: AppColors.divider,
    cardColor: AppColors.elevatedSurface,
    useMaterial3: true,
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColorsLight.baseBackground,
    colorScheme: ColorScheme.light(
      primary: AppColorsLight.accent,
      surface: AppColorsLight.sidebarBackground,
      error: AppColorsLight.error,
    ),
    fontFamily: 'Inter',
    dividerColor: AppColorsLight.divider,
    cardColor: AppColorsLight.elevatedSurface,
    useMaterial3: true,
  );
}
```

- [ ] **Step 4: Wire theme to MaterialApp in app_root.dart**

Read `lib/core/app_root.dart`, then update `MaterialApp` (or `ShadApp`) to use both themes:

```dart
// Find the MaterialApp / ShadApp widget and update:
theme: ThemeManager.lightTheme,
darkTheme: ThemeManager.darkTheme,
themeMode: themeManager.themeMode,
```

Where `themeManager` is obtained via `context.watch<ThemeManager>()` or `getIt<ThemeManager>()`. Wrap `MaterialApp` in a `ListenableBuilder` if it isn't already.

**Note:** The light theme applies globally — `AppColors.*` constants are for dark mode. Widgets relying on `AppColors.*` directly will not auto-switch; `Theme.of(context)` colors are what auto-switch. Full per-widget light-mode adaptation is out of scope for this plan — the ThemeData wiring gives the foundation.

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze lib/
```

Expected: No issues found.

```bash
git add lib/core/themes/theme_tokens.dart lib/core/themes/theme_manager.dart lib/core/app_root.dart
git commit -m "style: increase border radius and add light theme"
```

---

### Task 5: Endpoint Editor — Editable Name + Auto-Beautify Body

**Files:**
- Modify: `lib/features/shared/presentation/widgets/endpoint_editor.dart`

**Context:** `endpoint_editor.dart` already has `_nameCtrl` initialized but never displayed. It has a Beautify button on the body tab. The goal is to (a) add an editable name field in the top header bar and (b) replace the Beautify button with debounced auto-format on body text change.

- [ ] **Step 1: Add name text field to the editor header**

In the header `Container` (height 48, around line 318 in the current file) that shows method dropdown + URL + curl export + save button, add `_nameCtrl` as an editable field at the very top, above the URL row. Change the header to a `Column` with two rows: name row on top (32px), URL row below (48px).

Find this section:

```dart
Container(
  height: 48,
  padding: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    border: Border(bottom: BorderSide(color: AppColors.divider)),
  ),
  child: Row(
    children: [
      _MethodDropdown(...),
      const SizedBox(width: 8),
      Expanded(child: _UrlField(controller: _urlCtrl)),
      ...
    ],
  ),
),
```

Replace with:

```dart
Container(
  decoration: BoxDecoration(
    border: Border(bottom: BorderSide(color: AppColors.divider)),
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Name row
      Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.link, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                style: AppTypography.bodyMd,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Endpoint name',
                ),
                onChanged: (_) => _queueSync(),
              ),
            ),
          ],
        ),
      ),
      // URL row
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _MethodDropdown(
              value: _method,
              onChanged: (v) {
                setState(() => _method = v!);
                _queueSync();
              },
            ),
            const SizedBox(width: 8),
            Expanded(child: _UrlField(controller: _urlCtrl)),
            const SizedBox(width: 16),
            PilotButton.ghost(
              icon: LucideIcons.code,
              onPressed: _showExportCurlDialog,
              compact: true,
            ),
            const SizedBox(width: 8),
            PilotButton.ghost(
              icon: LucideIcons.save,
              onPressed: _save,
              compact: true,
            ),
          ],
        ),
      ),
    ],
  ),
),
```

- [ ] **Step 2: Add body debounce timer and remove Beautify button**

Declare a new timer for body auto-format at the top of `_EndpointEditorState`:

```dart
async_timer.Timer? _beautifyTimer;
```

In `dispose()`, cancel it:

```dart
_beautifyTimer?.cancel();
```

Add a new method `_scheduleBeautify()`:

```dart
void _scheduleBeautify() {
  _beautifyTimer?.cancel();
  _beautifyTimer = async_timer.Timer(const Duration(milliseconds: 700), () {
    final text = _bodyCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      if (pretty != _bodyCtrl.text) {
        final sel = _bodyCtrl.selection;
        _bodyCtrl.value = TextEditingValue(
          text: pretty,
          selection: sel.isValid && sel.end <= pretty.length
              ? sel
              : TextSelection.collapsed(offset: pretty.length),
        );
      }
    } catch (_) {
      // not valid JSON — leave as is
    }
  });
}
```

In the body `TextField` `onChanged`, call `_scheduleBeautify()` in addition to `_queueSync()`:

```dart
onChanged: (v) {
  _queueSync();
  _scheduleBeautify();
},
```

Find the Beautify button in the body tab (around line 427) and delete it entirely:

```dart
// DELETE:
PilotButton.ghost(
  label: 'Beautify',
  icon: LucideIcons.braces,
  onPressed: _beautifyJson,
  compact: true,
),
```

Keep `_beautifyJson()` method (it's also used elsewhere for curl export). Only remove the button.

- [ ] **Step 3: Analyze and commit**

```bash
flutter analyze lib/features/shared/presentation/widgets/endpoint_editor.dart
```

Expected: No issues found.

```bash
git add lib/features/shared/presentation/widgets/endpoint_editor.dart
git commit -m "feat: add inline name editing and auto-beautify body in endpoint editor"
```

---

### Task 6: Fix Keymaps + Double-Shift Global Search

**Files:**
- Modify: `lib/core/input/global_shortcut_listener.dart`
- Modify: `lib/core/navigation/app_router.dart` (verify `recentRunsRoute` exists — it does)
- Ensure: `lib/features/shared/presentation/widgets/global_search_dropdown.dart` exists (it does, 445 lines)

**Issues found:**
1. `nav.runs` action navigates to `projectsRoute` — should go to `recentRunsRoute`
2. `flow.save` action is empty
3. Double-Shift to open `GlobalSearchDropdown` is not implemented

- [ ] **Step 1: Fix nav.runs route in global_shortcut_listener.dart**

```dart
case 'nav.runs':
  AppNavigator.pushNamed(AppRouter.recentRunsRoute);
  return true;
```

- [ ] **Step 2: Implement double-Shift detection**

Add state to `_GlobalShortcutListenerState`:

```dart
DateTime? _lastShiftPressTime;
final _shiftDoubleTapThreshold = const Duration(milliseconds: 400);
```

In `_handleKeyEvent`, add Shift detection **before** the keymap loop:

```dart
bool _handleKeyEvent(KeyEvent event) {
  if (event is! KeyDownEvent) return false;

  // Double-Shift → global search
  if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
      event.logicalKey == LogicalKeyboardKey.shiftRight) {
    final now = DateTime.now();
    if (_lastShiftPressTime != null &&
        now.difference(_lastShiftPressTime!) < _shiftDoubleTapThreshold) {
      _lastShiftPressTime = null;
      _performAction('search.anywhere');
      return true;
    }
    _lastShiftPressTime = now;
    return false;
  }

  final provider = getIt<KeymapProvider>();
  for (final entry in provider.cachedActivators) {
    if (entry.key.accepts(event, HardwareKeyboard.instance)) {
      return _performAction(entry.value);
    }
  }
  return false;
}
```

- [ ] **Step 3: Add search.anywhere action + show GlobalSearchDropdown overlay**

Add `search.anywhere` case to `_performAction` and show `GlobalSearchDropdown` as a dialog/overlay:

```dart
case 'search.anywhere':
  _showGlobalSearch();
  return true;
```

Add method to the state:

```dart
void _showGlobalSearch() {
  final ctx = AppNavigator.navigatorKey.currentContext;
  if (ctx == null) return;
  showDialog<void>(
    context: ctx,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    builder: (_) => const _GlobalSearchDialog(),
  );
}
```

Add `_GlobalSearchDialog` widget at the bottom of the file:

```dart
class _GlobalSearchDialog extends StatelessWidget {
  const _GlobalSearchDialog();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.4),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxHeight: 480),
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: AppRadius.br8,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: const GlobalSearchDropdown(),
        ),
      ),
    );
  }
}
```

Add import at the top of the file:

```dart
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/shared/presentation/widgets/global_search_dropdown.dart';
```

- [ ] **Step 4: Analyze and commit**

```bash
flutter analyze lib/core/input/global_shortcut_listener.dart
```

Expected: No issues found.

```bash
git add lib/core/input/global_shortcut_listener.dart
git commit -m "feat: fix nav.runs keymap, add double-Shift global search overlay"
```

---

### Task 7: bitsdojo_window — Custom Window Chrome (Linux + Windows)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `linux/my_application.cc` (remove title bar)
- Modify: `windows/runner/main.cpp` (remove title bar)
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`
- Create: `lib/core/window/window_manager.dart`

**Note:** bitsdojo_window replaces the OS title bar. Mac does NOT need this (Flutter on Mac handles it natively). Only Linux and Windows.

- [ ] **Step 1: Add bitsdojo_window to pubspec.yaml**

```yaml
dependencies:
  bitsdojo_window: ^0.1.6
```

Run:

```bash
flutter pub get
```

- [ ] **Step 2: Configure native side for Linux**

In `linux/my_application.cc`, find `gtk_window_set_title` and add before `gtk_widget_show`:

```cpp
// Add after window creation:
gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
```

Alternatively, bitsdojo_window handles this automatically with `doWhenWindowReady`. Skip manual GTK edits if bitsdojo handles it. Check bitsdojo README for the exact Linux setup — the key call is in Dart:

```dart
// In main() before runApp:
WidgetsFlutterBinding.ensureInitialized();
doWhenWindowReady(() {
  appWindow.minSize = const Size(800, 600);
  appWindow.size = const Size(1280, 800);
  appWindow.alignment = Alignment.center;
  appWindow.title = 'StressPilot';
  appWindow.show();
});
```

- [ ] **Step 3: Create window_manager.dart**

Create `lib/core/window/window_manager.dart`:

```dart
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';

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
```

Call `WindowSetup.initialize()` in `main()` in `lib/main.dart` before `runApp`.

- [ ] **Step 4: Add window chrome (traffic lights) to WorkspaceNavBar**

Import bitsdojo in workspace_nav_bar.dart:

```dart
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:stress_pilot/core/window/window_manager.dart';
```

At the very start of the Row children in `WorkspaceNavBar.build`, add the window buttons on the left, wrapped in a platform guard:

```dart
// Left edge: Mac-style window buttons (Linux + Windows only)
if (WindowSetup.isSupported) ...[
  _WindowButtons(),
  const SizedBox(width: 8),
],
// Then: Play, Env, project picker, etc.
```

Add `_WindowButtons` widget at the bottom of the file:

```dart
class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TrafficLight(
          color: const Color(0xFFFF5F57),
          hoverIcon: Icons.close,
          onTap: () => appWindow.close(),
        ),
        const SizedBox(width: 6),
        _TrafficLight(
          color: const Color(0xFFFFBD2E),
          hoverIcon: Icons.remove,
          onTap: () => appWindow.minimize(),
        ),
        const SizedBox(width: 6),
        _TrafficLight(
          color: const Color(0xFF28C840),
          hoverIcon: Icons.crop_square,
          onTap: () => appWindow.maximizeOrRestore(),
        ),
      ],
    );
  }
}

class _TrafficLight extends StatefulWidget {
  final Color color;
  final IconData hoverIcon;
  final VoidCallback onTap;
  const _TrafficLight({required this.color, required this.hoverIcon, required this.onTap});

  @override
  State<_TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<_TrafficLight> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: widget.color.withValues(alpha: 0.7), width: 0.5),
          ),
          child: _isHovered
              ? Icon(widget.hoverIcon, size: 8, color: Colors.black.withValues(alpha: 0.5))
              : null,
        ),
      ),
    );
  }
}
```

Also wrap the entire NavBar `Container` in a `MoveWindow` widget so dragging the title bar moves the window:

```dart
return MoveWindow(
  child: Container(
    height: AppSpacing.navBarHeight,
    // ... existing decoration
    child: Row(children: [...]),
  ),
);
```

- [ ] **Step 5: Add border to window**

In `lib/core/app_root.dart` or the top-level widget, wrap the root in `WindowBorder` if on Linux/Windows:

```dart
Widget build(BuildContext context) {
  Widget child = /* existing root widget */;
  if (WindowSetup.isSupported) {
    child = WindowBorder(color: AppColors.border, width: 1, child: child);
  }
  return child;
}
```

- [ ] **Step 6: Analyze and commit**

```bash
flutter analyze lib/
```

Expected: No issues found.

```bash
git add pubspec.yaml pubspec.lock lib/core/window/window_manager.dart \
  lib/features/projects/presentation/widgets/workspace_nav_bar.dart \
  lib/core/app_root.dart
git commit -m "feat: add bitsdojo_window custom chrome with Mac-style traffic lights"
```

---

---

### Task 8: Canvas Node Compact Padding + Sidebar Drag-to-Canvas

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

**Context:** Endpoint nodes in the canvas have `padding: EdgeInsets.all(12)` (12px all sides) plus 8px internal gaps — too tall. Node height is 100px. Reduce to a tighter layout. Sidebar `_EndpointRow` has no `Draggable` — add it so endpoints can be dragged onto the flow canvas.

**Compact padding rules:**
- Node container padding: `EdgeInsets.symmetric(horizontal: 10, vertical: 6)` (was `all(12)`)
- Gap between method badge row and name: `SizedBox(height: 4)` (was 8)
- Gap between name and URL: `SizedBox(height: 2)` (unchanged)
- Gap between URL and badges: `SizedBox(height: 4)` (was 8)
- Endpoint node drop height: `80` (was `100`)

- [ ] **Step 1: Shrink endpoint node padding in workspace_canvas.dart**

In `_NodeWidget._buildEndpoint()` around line 1088, change:

```dart
// Before:
Container(
  width: node.width,
  constraints: BoxConstraints(minHeight: node.height),
  padding: const EdgeInsets.all(12),
  // ...
  child: Column(
    // ...
    children: [
      Row(/* method badge */),
      const SizedBox(height: 8),   // <- too big
      Text(/* name */),
      const SizedBox(height: 2),
      Text(/* url */),
      const SizedBox(height: 8),   // <- too big
      Wrap(/* badges */),
    ],
  ),
),

// After:
Container(
  width: node.width,
  constraints: BoxConstraints(minHeight: node.height),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(/* method badge — unchanged */),
      const SizedBox(height: 4),
      Text(/* name — unchanged */),
      const SizedBox(height: 2),
      Text(/* url — unchanged */),
      const SizedBox(height: 4),
      Wrap(/* badges — unchanged */),
    ],
  ),
),
```

Also in `_handleDrop()` around line 418, change endpoint node height from `100` to `80`:

```dart
height: type == FlowNodeType.start
    ? 56
    : (type == FlowNodeType.branch
    ? 100
    : (type == FlowNodeType.subflow ? 64 : 80)),  // was 100
```

- [ ] **Step 2: Add Draggable to _EndpointRow in workspace_sidebar.dart**

Add imports at the top of `workspace_sidebar.dart`:

```dart
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';
```

In `_EndpointRowState.build()`, wrap the current `MouseRegion` → `GestureDetector` → `Container` in a `Draggable<DragData>`:

```dart
return Draggable<DragData>(
  data: DragData(
    type: FlowNodeType.endpoint,
    payload: {
      'id': widget.endpoint.id,
      'name': widget.endpoint.name,
      'method': widget.endpoint.httpMethod,
      'url': widget.endpoint.url,
      'type': widget.endpoint.type,
    },
  ),
  feedback: Material(
    color: Colors.transparent,
    child: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: AppRadius.br6,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        widget.endpoint.name,
        style: AppTypography.bodyMd,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
  childWhenDragging: Opacity(opacity: 0.4, child: _buildRow()),
  child: _buildRow(),
);
```

Extract the existing `MouseRegion(...)` content into a private `_buildRow()` method inside `_EndpointRowState`:

```dart
Widget _buildRow() {
  final type = widget.endpoint.type.toUpperCase();
  final typeColor = _getTypeColor(type);

  return MouseRegion(
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: AppSpacing.sidebarRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.activeItem
              : (_isHovered ? AppColors.hoverItem : Colors.transparent),
          border: widget.isSelected
              ? Border(left: BorderSide(color: AppColors.accent, width: 2))
              : null,
        ),
        child: Row(
          children: [
            _TypeBadge(type: type, color: typeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.endpoint.name,
                style: AppTypography.code.copyWith(
                  color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isHovered) ...[
              _IconButton(icon: LucideIcons.pencil, onTap: widget.onEdit),
              _IconButton(icon: LucideIcons.trash2, onTap: widget.onDelete),
            ],
          ],
        ),
      ),
    ),
  );
}
```

Also add `FlowNodeType` import since it's needed by `DragData`:

```dart
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
// Already exists. DragData also needs:
import 'package:stress_pilot/features/projects/domain/models/canvas.dart';
```

Note: `FlowNodeType.endpoint` is in `canvas.dart` (same file as `DragData`).

- [ ] **Step 3: Analyze and commit**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart \
  lib/features/projects/presentation/widgets/workspace_sidebar.dart
```

Expected: No issues found.

```bash
git add lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart \
  lib/features/projects/presentation/widgets/workspace_sidebar.dart
git commit -m "fix: compact canvas node padding and add drag-to-canvas from sidebar"
```

---

### Task 9: Agent Panel Collapse Button + Response Panel Cleanup

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Modify: `lib/features/shared/presentation/widgets/endpoint_editor.dart`

**Goals:**
1. `_AgentPanel`: add a `×` / collapse button at top-right of header → calls `onClose` callback → sets `_isAgentOpen = false` in workspace page.
2. `EndpointEditor` response panel: remove the Search icon button (Ctrl+F still opens search). Add a collapse/expand toggle button to completely hide the response panel.

- [ ] **Step 1: Add onClose to _AgentPanel and wire it up**

In `project_workspace_page.dart`, update `_AgentPanel` to accept `onClose`:

```dart
class _AgentPanel extends StatelessWidget {
  final VoidCallback? onClose;
  const _AgentPanel({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.sidebarBackground,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('Agent', style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary)),
                const Spacer(),
                if (onClose != null)
                  _PanelCloseButton(onTap: onClose!),
              ],
            ),
          ),
          const Expanded(child: AgentTerminalView()),
        ],
      ),
    );
  }
}
```

Add `_PanelCloseButton` widget at the bottom of the file:

```dart
class _PanelCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PanelCloseButton({required this.onTap});

  @override
  State<_PanelCloseButton> createState() => _PanelCloseButtonState();
}

class _PanelCloseButtonState extends State<_PanelCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Icon(LucideIcons.minus, size: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
```

Update the `_AgentPanel` usage in `_ProjectWorkspacePageState.build()`:

```dart
// Change this:
panel: const _AgentPanel(),
// To:
panel: _AgentPanel(onClose: _toggleAgent),
```

- [ ] **Step 2: Remove search button, add collapse toggle in response panel**

In `endpoint_editor.dart`, add `_isResponseOpen` state field:

```dart
bool _isResponseOpen = true;
```

In the response panel drag handle (around line 440), wrap `SizedBox(height: respH, child: ...)` to only show when `_isResponseOpen`:

```dart
// Before:
MouseRegion(/* drag handle */),
SizedBox(
  height: respH,
  child: /* response panel */,
),

// After:
MouseRegion(/* drag handle — only show when open */),
if (_isResponseOpen)
  SizedBox(
    height: respH,
    child: /* response panel */,
  ),
```

In the response panel header `Row` (around line 481), remove the search `PilotButton.ghost` entirely:

```dart
// DELETE this block:
PilotButton.ghost(
  icon: LucideIcons.search,
  compact: true,
  onPressed: () {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) _searchFocusNode.requestFocus();
    });
  },
),
```

Add a collapse button after the spacer in the same row:

```dart
// After the Spacer() and status badge, add:
const SizedBox(width: 4),
_PanelCollapseButton(
  isOpen: _isResponseOpen,
  onTap: () => setState(() => _isResponseOpen = !_isResponseOpen),
),
```

Add `_PanelCollapseButton` widget at the bottom of `endpoint_editor.dart`:

```dart
class _PanelCollapseButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _PanelCollapseButton({required this.isOpen, required this.onTap});

  @override
  State<_PanelCollapseButton> createState() => _PanelCollapseButtonState();
}

class _PanelCollapseButtonState extends State<_PanelCollapseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Icon(
            widget.isOpen ? LucideIcons.chevronDown : LucideIcons.chevronUp,
            size: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
```

Also update the drag handle to only be interactive when `_isResponseOpen`:

```dart
// Before: MouseRegion(cursor: resizeRow, ...)
// After: only apply resizeRow cursor when open
MouseRegion(
  cursor: _isResponseOpen ? SystemMouseCursors.resizeRow : SystemMouseCursors.basic,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: _isResponseOpen ? (d) {
      setState(() {
        _responsePanelHeight = (_responsePanelHeight - d.delta.dy)
            .clamp(40.0, totalH - 100.0);
      });
    } : null,
    child: /* existing handle Container */,
  ),
),
```

- [ ] **Step 3: Analyze and commit**

```bash
flutter analyze lib/features/projects/presentation/pages/project_workspace_page.dart \
  lib/features/shared/presentation/widgets/endpoint_editor.dart
```

Expected: No issues found.

```bash
git add lib/features/projects/presentation/pages/project_workspace_page.dart \
  lib/features/shared/presentation/widgets/endpoint_editor.dart
git commit -m "feat: add collapse button to agent panel and response panel, remove search button"
```

---

### Task 10: Extract Shared Widgets — Deduplication

**Files:**
- Create: `lib/features/shared/presentation/widgets/field_label.dart`
- Modify: `lib/features/projects/presentation/widgets/run_flow_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/flow_dialog.dart`
- Modify: `lib/features/shared/presentation/widgets/create_endpoint_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/project/project_dialog.dart`
- Create: `lib/features/shared/presentation/widgets/sidebar_section_header.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_node_library.dart`

**Goals:** Extract `_FieldLabel` (duplicated in 4 files) and `_SectionHeader` (duplicated in 2 files) to shared. Do NOT touch canvas_provider, results_page, or agent files — scope is widgets only.

- [ ] **Step 1: Create shared FieldLabel widget**

Create `lib/features/shared/presentation/widgets/field_label.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: AppTypography.label,
      ),
    );
  }
}
```

- [ ] **Step 2: Replace _FieldLabel in all 4 files**

In each file, add the import and replace `_FieldLabel('...')` with `FieldLabel('...')`:

```dart
import 'package:stress_pilot/features/shared/presentation/widgets/field_label.dart';
```

Files to update:
- `lib/features/projects/presentation/widgets/run_flow_dialog.dart`: replace all `_FieldLabel(` with `FieldLabel(`, delete the `_FieldLabel` class
- `lib/features/projects/presentation/widgets/flow_dialog.dart`: same
- `lib/features/shared/presentation/widgets/create_endpoint_dialog.dart`: same
- `lib/features/projects/presentation/widgets/project/project_dialog.dart`: same

- [ ] **Step 3: Create shared SidebarSectionHeader widget**

Create `lib/features/shared/presentation/widgets/sidebar_section_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

class SidebarSectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onToggle;
  final bool isExpanded;

  const SidebarSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.onToggle,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: AppSpacing.sidebarRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.label,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Replace _SectionHeader in workspace_sidebar.dart and workspace_node_library.dart**

In `workspace_sidebar.dart`:
```dart
import 'package:stress_pilot/features/shared/presentation/widgets/sidebar_section_header.dart';
```

Replace all `_SectionHeader(` usages with `SidebarSectionHeader(` with matching parameters. Delete the `_SectionHeader` class from the file.

In `workspace_node_library.dart`:
```dart
import 'package:stress_pilot/features/shared/presentation/widgets/sidebar_section_header.dart';
```

Replace `_SectionHeader(` with `SidebarSectionHeader(`. Delete the `_SectionHeader` class.

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze lib/features/shared/presentation/widgets/ \
  lib/features/projects/presentation/widgets/
```

Expected: No issues found.

```bash
git add lib/features/shared/presentation/widgets/field_label.dart \
  lib/features/shared/presentation/widgets/sidebar_section_header.dart \
  lib/features/projects/presentation/widgets/run_flow_dialog.dart \
  lib/features/projects/presentation/widgets/flow_dialog.dart \
  lib/features/shared/presentation/widgets/create_endpoint_dialog.dart \
  lib/features/projects/presentation/widgets/project/project_dialog.dart \
  lib/features/projects/presentation/widgets/workspace_sidebar.dart \
  lib/features/projects/presentation/widgets/workspace/workspace_node_library.dart
git commit -m "refactor: extract FieldLabel and SidebarSectionHeader to shared widgets"
```

---

## Quality Gate

After all tasks, run:

```bash
flutter analyze lib/
```

Expected: No issues found. Fix any errors before marking the plan complete.
