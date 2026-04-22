# Workspace Polish & UX Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the workspace UI — Montserrat font, resizable sidebar, clickable project picker, play/stop action bar, icon-only ENV badge, and subtle shadows/margins to visually separate components.

**Architecture:** All changes are pure UI — no logic, no state changes beyond what already exists. Uses existing `EndpointProvider.executeEndpoint/cancelExecution`, `FlowProvider.runFlow`, `RunFlowDialog`, and `ProjectProvider.selectProject`. Feature-first: new widgets used by one feature stay private (underscore prefix) in their page file; reusable ones go to `lib/features/shared/presentation/widgets/`.

**Tech Stack:** Flutter (Dart), Provider, google_fonts (already in pubspec), lucide_icons, shadcn_ui

**Quality gate (mandatory after every task):**
```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/
```
Zero errors before every commit.

**Reference design:** JetBrains Fleet — dark panels, subtle shadows, monospace code, human-readable sans-serif UI text, clean separation of sidebar / tab bar / content.

---

## Key existing APIs (do not re-implement)

| Symbol | File | Signature |
|--------|------|-----------|
| `EndpointProvider.executeEndpoint` | `lib/features/shared/presentation/provider/endpoint_provider.dart:237` | `Future<Map<String,dynamic>> executeEndpoint(int endpointId, {String? bodyJson})` |
| `EndpointProvider.cancelExecution` | `:279` | `void cancelExecution(int endpointId)` |
| `EndpointProvider.isEndpointExecuting` | `:286` | `bool isEndpointExecuting(int endpointId)` |
| `FlowProvider.runFlow` | `lib/features/shared/presentation/provider/flow_provider.dart:212` | `Future<String> runFlow({required int flowId, required RunFlowRequest runFlowRequest, MultipartFile? file})` |
| `RunFlowDialog` | `lib/features/projects/presentation/widgets/run_flow_dialog.dart` | `RunFlowDialog({required int flowId})` |
| `ProjectProvider.selectProject` | `lib/features/shared/presentation/provider/project_provider.dart` | `Future<void> selectProject(Project project)` |
| `ProjectProvider.loadProjects` | same | `Future<void> loadProjects({String? searchName})` |
| `WorkspaceTabProvider.activeTab` | `lib/features/projects/presentation/provider/workspace_tab_provider.dart` | `WorkspaceTab? activeTab` |
| `WorkspaceTabType` | same | `enum WorkspaceTabType { flow, endpoint }` |

---

## File Map

| File | Action | What changes |
|------|--------|-------------|
| `lib/core/themes/theme_tokens.dart` | Modify | Non-code typography → Montserrat via GoogleFonts |
| `lib/features/projects/presentation/pages/project_workspace_page.dart` | Modify | Resizable sidebar, play/stop bar, ENV icon-only, shadows/margins |
| `lib/features/projects/presentation/widgets/workspace_nav_bar.dart` | Modify | Project name → clickable project picker popup |
| `lib/features/projects/presentation/widgets/workspace_sidebar.dart` | Modify | Remove fixed width (width controlled by parent now) |
| `lib/features/projects/presentation/widgets/workspace_tab_bar.dart` | Modify | Subtle rounded tab, slight shadow |
| `lib/features/projects/presentation/pages/recent_activity_page.dart` | Modify | Montserrat picks up automatically via token; slight margin polish |

---

## Task 1: Montserrat font for UI text

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`

Montserrat is served via `google_fonts` (already in pubspec). JetBrains Mono stays for `code`, `codeSm`, `codePath`. All human-readable text styles switch to Montserrat.

- [ ] **Step 1: Read the current AppTypography class**

Read `lib/core/themes/theme_tokens.dart` lines 86–98 to see current text style getters.

- [ ] **Step 2: Add GoogleFonts import and update AppTypography**

In `lib/core/themes/theme_tokens.dart`, add at the top (already imports flutter/material.dart and google_fonts):

Verify `import 'package:google_fonts/google_fonts.dart';` is present. If missing, add it.

Then replace the entire `abstract class AppTypography` block with:

```dart
abstract class AppTypography {
  static const _mono = 'JetBrains Mono';

  // Human-readable UI text — Montserrat
  static TextStyle get caption => GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get body    => GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get bodyMd  => GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get bodyLg  => GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get heading => GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get title   => GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get label   => GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3, color: AppColors.textSecondary);

  // Code / paths / keys — JetBrains Mono (unchanged)
  static TextStyle get codeSm   => TextStyle(fontFamily: _mono, fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get code     => TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get codePath => TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}
```

- [ ] **Step 3: Analyze**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/
```
Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/themes/theme_tokens.dart
git commit -m "style: switch UI typography to Montserrat, keep JetBrains Mono for code"
```

---

## Task 2: Resizable sidebar panel

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

The sidebar is currently `width: 260` hardcoded inside `WorkspaceSidebar`. Make width controlled by the parent via a constructor param, and add a drag handle divider in `ProjectWorkspacePage`.

- [ ] **Step 1: Read current WorkspaceSidebar**

Read `lib/features/projects/presentation/widgets/workspace_sidebar.dart` lines 1–45. Note the `Container(width: 260, ...)`.

- [ ] **Step 2: Add width param to WorkspaceSidebar**

In `workspace_sidebar.dart`, change `WorkspaceSidebar` to accept a `width` parameter:

```dart
class WorkspaceSidebar extends StatelessWidget {
  final double width;
  const WorkspaceSidebar({super.key, this.width = 260});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: AppColors.sidebarBackground,
      // ... rest unchanged
    );
  }
}
```

- [ ] **Step 3: Add _sidebarWidth state and drag handle to ProjectWorkspacePage**

Read `lib/features/projects/presentation/pages/project_workspace_page.dart` fully.

In `_ProjectWorkspacePageState`, add:
```dart
double _sidebarWidth = 260;
static const double _minSidebarWidth = 180;
static const double _maxSidebarWidth = 480;
```

Replace the `Row` that contains `WorkspaceSidebar` + `Expanded(content)` with:

```dart
Row(
  children: [
    WorkspaceSidebar(width: _sidebarWidth),
    // Drag handle
    MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _sidebarWidth = (_sidebarWidth + details.delta.dx)
                .clamp(_minSidebarWidth, _maxSidebarWidth);
          });
        },
        child: Container(
          width: 4,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: AppColors.divider,
            ),
          ),
        ),
      ),
    ),
    Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.baseBackground,
        ),
        child: Column(
          children: [
            const WorkspaceTabBar(),
            if (project != null && project.environmentId != 0)
              _buildActionBar(project, activeTab),
            Expanded(child: _buildTabContent(activeTab)),
          ],
        ),
      ),
    ),
  ],
)
```

Note: `_buildActionBar` is added in Task 4. For now keep the existing env badge row.

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/
```
Expected: zero errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_sidebar.dart \
        lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "feat: resizable sidebar panel with drag handle"
```

---

## Task 3: Clickable project name → project picker

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`

The project name on the left of the nav bar is plain `Text`. Replace with a clickable widget that shows a popup menu listing all projects from `ProjectProvider.projects`. Clicking a project calls `ProjectProvider.selectProject(project)` (which already persists to SharedPreferences and notifies listeners — workspace auto-reloads via `didChangeDependencies`).

- [ ] **Step 1: Read workspace_nav_bar.dart fully**

Read the file. Note the left side is:
```dart
Text(
  project?.name ?? 'No Project',
  style: AppTypography.body.copyWith(color: secondaryText),
),
```

- [ ] **Step 2: Replace with _ProjectNameButton**

In `workspace_nav_bar.dart`, change `WorkspaceNavBar.build` left side to:

```dart
_ProjectNameButton(projectName: project?.name ?? 'No Project'),
```

Add the `_ProjectNameButton` private widget at the bottom of the file:

```dart
class _ProjectNameButton extends StatefulWidget {
  final String projectName;
  const _ProjectNameButton({required this.projectName});

  @override
  State<_ProjectNameButton> createState() => _ProjectNameButtonState();
}

class _ProjectNameButtonState extends State<_ProjectNameButton> {
  bool _isHovered = false;

  Future<void> _showProjectPicker(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    await provider.loadProjects();

    if (!context.mounted) return;

    final projects = provider.projects;
    if (projects.isEmpty) return;

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<int>(
      context: context,
      position: position,
      color: AppColors.elevatedSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.br6,
        side: BorderSide(color: AppColors.border),
      ),
      items: projects.map((p) => PopupMenuItem<int>(
        value: p.id,
        height: 36,
        child: Text(
          p.name,
          style: AppTypography.body.copyWith(
            color: provider.selectedProject?.id == p.id
                ? AppColors.accent
                : AppColors.textPrimary,
          ),
        ),
      )).toList(),
    );

    if (selected != null && context.mounted) {
      final project = projects.firstWhere((p) => p.id == selected);
      await context.read<ProjectProvider>().selectProject(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _showProjectPicker(context),
        child: AnimatedContainer(
          duration: AppDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.projectName,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronsUpDown, size: 12, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
```

Add import at top of file: `import 'package:shadcn_ui/shadcn_ui.dart';`

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/projects/presentation/widgets/workspace_nav_bar.dart
```
Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_nav_bar.dart
git commit -m "feat: clickable project name opens project picker popup"
```

---

## Task 4: Action bar — icon-only ENV + play/stop button

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`

Replace the current env badge row (which shows `settings2` icon + "ENV" text) with a proper action bar that has:
1. ENV: icon-only `settings2` button (tooltip "Environment") — same navigation as before
2. Play/Stop button:
   - No active tab → greyed out play icon, disabled
   - Active tab = flow → play icon, on tap show `RunFlowDialog(flowId: flow.id)`
   - Active tab = endpoint, not executing → play icon, on tap call `endpointProvider.executeEndpoint(endpoint.id)`
   - Active tab = endpoint, executing → stop icon (`LucideIcons.squareStop`), on tap call `endpointProvider.cancelExecution(endpoint.id)`

- [ ] **Step 1: Read project_workspace_page.dart fully**

Read the file. Note the env badge Container block (lines 77–93 approx) and the `_EnvBadge` class.

- [ ] **Step 2: Replace env badge row with _ActionBar**

In `_ProjectWorkspacePageState.build`, replace the conditional env badge Container:

```dart
if (project != null && project.environmentId != 0)
  Container(
    height: 28,
    ...
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [_EnvBadge(...)]),
  ),
```

With:

```dart
_ActionBar(
  project: project,
  activeTab: activeTab,
),
```

Make `_ActionBar` always visible (even when project is null — just shows disabled buttons).

- [ ] **Step 3: Add _ActionBar widget**

Add at the bottom of `project_workspace_page.dart` (before `_EnvBadge` class, or replace it):

```dart
class _ActionBar extends StatelessWidget {
  final Project? project;
  final WorkspaceTab? activeTab;

  const _ActionBar({required this.project, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _PlayStopButton(project: project, activeTab: activeTab),
          const SizedBox(width: AppSpacing.xs),
          if (project != null && project!.environmentId != 0)
            _EnvIconButton(
              environmentId: project!.environmentId,
              projectName: project!.name,
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add _EnvIconButton (replaces old _EnvBadge)**

```dart
class _EnvIconButton extends StatefulWidget {
  final int environmentId;
  final String projectName;
  const _EnvIconButton({required this.environmentId, required this.projectName});

  @override
  State<_EnvIconButton> createState() => _EnvIconButtonState();
}

class _EnvIconButtonState extends State<_EnvIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Environment',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => AppNavigator.pushNamed(
            AppRouter.projectEnvironmentRoute,
            arguments: {
              'environmentId': widget.environmentId,
              'projectName': widget.projectName,
            },
          ),
          child: Container(
            width: 28,
            height: 24,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(
              LucideIcons.settings2,
              size: 14,
              color: _isHovered ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Add _PlayStopButton**

```dart
class _PlayStopButton extends StatefulWidget {
  final Project? project;
  final WorkspaceTab? activeTab;
  const _PlayStopButton({required this.project, required this.activeTab});

  @override
  State<_PlayStopButton> createState() => _PlayStopButtonState();
}

class _PlayStopButtonState extends State<_PlayStopButton> {
  bool _isHovered = false;

  bool get _isFlow => widget.activeTab?.type == WorkspaceTabType.flow;
  bool get _isEndpoint => widget.activeTab?.type == WorkspaceTabType.endpoint;

  @override
  Widget build(BuildContext context) {
    final endpointProvider = context.watch<EndpointProvider>();

    final endpoint = _isEndpoint ? widget.activeTab!.data as Endpoint : null;
    final isExecuting = endpoint != null && endpointProvider.isEndpointExecuting(endpoint.id);

    final bool canAct = widget.activeTab != null && widget.project != null;
    final IconData icon = isExecuting ? LucideIcons.squareStop : LucideIcons.play;
    final Color iconColor = canAct
        ? (isExecuting ? AppColors.error : AppColors.methodGet)
        : AppColors.textDisabled;

    final String tooltip = isExecuting
        ? 'Stop'
        : (_isFlow ? 'Run Flow' : (_isEndpoint ? 'Run Endpoint' : 'Run'));

    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: canAct ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: canAct ? () => _handleTap(context, endpointProvider, isExecuting, endpoint) : null,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 28,
            height: 24,
            decoration: BoxDecoration(
              color: _isHovered && canAct ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    EndpointProvider endpointProvider,
    bool isExecuting,
    Endpoint? endpoint,
  ) {
    if (_isFlow) {
      final flow = widget.activeTab!.data as flow_domain.Flow;
      showDialog(
        context: context,
        builder: (_) => RunFlowDialog(flowId: flow.id),
      );
      return;
    }

    if (_isEndpoint && endpoint != null) {
      if (isExecuting) {
        endpointProvider.cancelExecution(endpoint.id);
      } else {
        endpointProvider.executeEndpoint(endpoint.id);
      }
    }
  }
}
```

Add required imports at top of `project_workspace_page.dart`:
```dart
import 'package:stress_pilot/features/projects/presentation/widgets/run_flow_dialog.dart';
import 'package:stress_pilot/features/projects/domain/models/flow.dart' as flow_domain;
```

- [ ] **Step 6: Remove the old _EnvBadge class**

Delete the `_EnvBadge` StatefulWidget class — replaced by `_EnvIconButton`.

- [ ] **Step 7: Analyze**

```bash
flutter analyze lib/features/projects/presentation/pages/project_workspace_page.dart
```
Expected: zero errors.

- [ ] **Step 8: Commit**

```bash
git add lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "feat: action bar with icon-only ENV button and play/stop run button"
```

---

## Task 5: Visual polish — shadows, margins, rounded corners

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`
- Modify: `lib/features/projects/presentation/pages/recent_activity_page.dart`
- Modify: `lib/core/themes/theme_tokens.dart` (add shadow tokens)

Target look: panels visually separated, slight depth, feel like JetBrains Fleet with a touch of warmth. Not heavy card UI — subtle.

- [ ] **Step 1: Add shadow tokens to theme_tokens.dart**

In `lib/core/themes/theme_tokens.dart`, add after `AppDurations`:

```dart
abstract class AppShadows {
  // Panel shadow — sidebar, floating elements
  static List<BoxShadow> get panel => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 8,
      offset: const Offset(2, 0),
    ),
  ];

  // Card shadow — dialogs, popovers
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Subtle — tab bar, action bar
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}
```

- [ ] **Step 2: Polish sidebar — shadow + rounded right edge**

In `lib/features/projects/presentation/widgets/workspace_sidebar.dart`, update the outer `Container`:

```dart
Container(
  width: width,
  decoration: BoxDecoration(
    color: AppColors.sidebarBackground,
    borderRadius: const BorderRadius.only(
      topRight: Radius.circular(0),
      bottomRight: Radius.circular(0),
    ),
    boxShadow: AppShadows.panel,
  ),
  // ... rest unchanged
)
```

Also add 8px left padding inside the sidebar sections for breathing room:
In `_SectionHeader.build`, change `padding` from `symmetric(horizontal: AppSpacing.sm)` to:
```dart
padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
```

- [ ] **Step 3: Polish workspace page — margins around content**

In `project_workspace_page.dart`, wrap the `Expanded(content)` area with a small margin:

In the `Row`, wrap the `Expanded` child content column with:
```dart
Expanded(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.xs), // 4px breathing room
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        borderRadius: AppRadius.br6,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const WorkspaceTabBar(),
          _ActionBar(project: project, activeTab: activeTab),
          Expanded(child: _buildTabContent(activeTab)),
        ],
      ),
    ),
  ),
),
```

This gives 4px gap between the drag handle and content, with subtle border + shadow on the content panel.

- [ ] **Step 4: Polish tab bar — active tab pill style**

In `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`, update `_WorkspaceTabWidget.build`:

Active tab decoration — add slight top radius:
```dart
decoration: BoxDecoration(
  color: widget.isActive ? AppColors.activeItem : Colors.transparent,
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(4),
  ),
  border: Border(
    bottom: BorderSide(
      color: widget.isActive ? AppColors.accent : Colors.transparent,
      width: 2,
    ),
  ),
),
```

- [ ] **Step 5: Polish recent activity page — card margins**

In `lib/features/projects/presentation/pages/recent_activity_page.dart`, update `_PanelContainer` or the inline panel containers to add `boxShadow: AppShadows.card`:

Find the container with `AppColors.sidebarBackground` and add:
```dart
boxShadow: AppShadows.card,
```

- [ ] **Step 6: Analyze**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/
```
Expected: zero errors.

- [ ] **Step 7: Commit**

```bash
git add lib/core/themes/theme_tokens.dart \
        lib/features/projects/presentation/pages/project_workspace_page.dart \
        lib/features/projects/presentation/widgets/workspace_sidebar.dart \
        lib/features/projects/presentation/widgets/workspace_tab_bar.dart \
        lib/features/projects/presentation/pages/recent_activity_page.dart
git commit -m "style: add shadows, margins, rounded tab corners for visual depth"
```

---

## Self-Review: Spec Coverage

| User requirement | Task |
|-----------------|------|
| Resizable window panels | Task 2 |
| Click project name to switch project | Task 3 |
| Montserrat font (human-readable) | Task 1 |
| ENV = icon only (no text) | Task 4 (_EnvIconButton) |
| Play button next to ENV | Task 4 (_PlayStopButton) |
| Flow tab: play → RunFlowDialog | Task 4 step 5 |
| Endpoint tab: play → execute, becomes stop | Task 4 step 5 |
| Stop button cancels endpoint execution | Task 4 step 5 |
| Rounded corners | Task 5 step 4 (tab bar) |
| Borders | Task 5 step 3 (content panel border) |
| Shadows | Task 5 steps 1-5 |
| Margins between components | Task 5 step 3 (4px padding) |
| Don't change logic — mimic prev behaviour | All tasks — only UI changes, same providers/dialogs |

**Placeholder scan:** No TBD found. All code blocks complete.

**Type consistency:**
- `flow_domain.Flow` used in Task 4 — matches `project_workspace_page.dart` existing import alias ✓
- `EndpointProvider.isEndpointExecuting(int)` → exists at line 286 ✓
- `EndpointProvider.cancelExecution(int)` → exists at line 279 ✓
- `RunFlowDialog(flowId: int)` → constructor confirmed ✓
- `AppShadows.panel/card/subtle` defined in Task 5 step 1 before used in steps 2-5 ✓
- `WorkspaceTabType.flow` / `.endpoint` → enum confirmed ✓

**Pre-implementation checks for Task 4:**
```bash
grep -n "executeEndpoint" lib/features/shared/presentation/provider/endpoint_provider.dart | head -5
# Confirm signature: executeEndpoint(int endpointId, {String? bodyJson})
```
