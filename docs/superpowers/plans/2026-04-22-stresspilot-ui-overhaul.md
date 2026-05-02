# StressPilot UI Overhaul — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-skin StressPilot to match JetBrains Fleet's visual language, wire workspace sidebar CRUD, add env badge, and replace the project landing page with a Recent Activity screen.

**Architecture:** Token file already exists at `lib/core/themes/theme_tokens.dart` with Fleet colors/spacing/typography. Workspace shell (nav bar, sidebar, tab bar) already built. Plan adds missing token aliases, wires sidebar CRUD, creates RecentActivityPage, adds env badge, and does a token pass on remaining screens. No logic or state changes.

**Feature-first rule:** Widget/provider/service used by ONE feature → lives in that feature's folder. Used by TWO OR MORE features → lives in `lib/features/shared/`. Core infrastructure (theme, routing, DI) → `lib/core/`. Verify placement before creating any new file.

**Tech Stack:** Flutter (Dart), Provider state management, SharedPreferences, shadcn_ui, lucide_icons

**Quality gate (mandatory after every task):**
```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/
```
Do not commit. Do not advance to next task. Until analyze exits with **zero errors**.

---

## What is ALREADY done (do not re-implement)

- `lib/core/themes/theme_tokens.dart` — Fleet color/spacing/typography tokens
- `lib/core/app_root.dart` — Launch flow (workspace if project selected, else projectsRoute)
- `lib/features/projects/presentation/pages/project_workspace_page.dart` — Workspace shell
- `lib/features/projects/presentation/widgets/workspace_nav_bar.dart` — Nav bar (Marketplace/Settings/Agent)
- `lib/features/projects/presentation/widgets/workspace_sidebar.dart` — Fleet-style sidebar with endpoints + flows listing
- `lib/features/projects/presentation/widgets/workspace_tab_bar.dart` — Tab bar with Fleet styling
- `lib/features/projects/presentation/provider/workspace_tab_provider.dart` — Tab state

## File Map

| File | Action | Feature-first placement | Responsibility |
|------|--------|------------------------|----------------|
| `lib/core/themes/theme_tokens.dart` | Modify | core — design tokens | Add `textMuted`, `br12`, `br16` aliases |
| `lib/features/projects/presentation/pages/recent_activity_page.dart` | Create | projects feature — single-feature page | New landing page when no project selected |
| `lib/core/navigation/app_router.dart` | Modify | core — routing | Route `projectsRoute` → `RecentActivityPage`; remove `projectEndpointsRoute` |
| `lib/features/projects/presentation/widgets/recent_pages_widget.dart` | Modify | projects feature — used only in projects | Endpoint tap → workspace route |
| `lib/features/projects/presentation/widgets/workspace_sidebar.dart` | Modify | projects feature — workspace-only | Wire CRUD for endpoints and flows |
| `lib/features/projects/presentation/pages/project_workspace_page.dart` | Modify | projects feature — workspace-only | Add environment badge widget |
| `lib/features/settings/presentation/pages/settings_page.dart` | Modify | settings feature | Fleet token pass |
| `lib/features/marketplace/presentation/pages/marketplace_page.dart` | Modify | marketplace feature | Fleet token pass |
| `lib/features/environments/presentation/pages/environment_page.dart` | Modify | environments feature | Fleet token pass |

**Shared placement check:** Any NEW widget created during this plan that is used across features goes to `lib/features/shared/presentation/widgets/`. The `_EnvBadge` widget (Task 5) is workspace-only → stays in `project_workspace_page.dart` as a private widget. The `_NewProjectButton` (Task 2) is RecentActivityPage-only → stays private there.

---

### Task 1: Add missing token aliases to theme_tokens.dart

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`

The codebase uses `AppColors.textMuted`, `AppRadius.br12`, and `AppRadius.br16` in many files but these are not defined. Fleet spec caps radius at 8px; the aliases map to the correct Fleet values so all usages get correct styling without touching every call site.

- [ ] **Step 1: Open the file and locate the two abstract classes**

Read `lib/core/themes/theme_tokens.dart`. Find the end of `AppColors` class and the end of `AppRadius` class.

- [ ] **Step 2: Add textMuted alias to AppColors**

In `lib/core/themes/theme_tokens.dart`, inside `abstract class AppColors`, after the `static Color get accentColor => accent;` line, add:

```dart
  // Alias used across codebase — same as textDisabled
  static Color get textMuted => textDisabled;
```

- [ ] **Step 3: Add br12 and br16 aliases to AppRadius**

In `lib/core/themes/theme_tokens.dart`, inside `abstract class AppRadius`, after `static const br8 = BorderRadius.all(r8);`, add:

```dart
  // Fleet caps radius at 8px; these aliases keep existing call sites compiling
  static const r12 = r8;
  static const r16 = r8;
  static const br12 = br8;
  static const br16 = br8;
```

- [ ] **Step 4: Verify no compile errors**

Run:
```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/core/themes/theme_tokens.dart
```
Expected: no errors

- [ ] **Step 5: Commit**

```bash
git add lib/core/themes/theme_tokens.dart
git commit -m "fix: add missing textMuted and br12/br16 token aliases"
```

---

### Task 2: Create RecentActivityPage

**Files:**
- Create: `lib/features/projects/presentation/pages/recent_activity_page.dart`

The app currently routes to `ProjectsPage` (which mixes project table + runs + recent activity) when no project is selected. Replace with a clean Fleet-styled Recent Activity screen that shows what `RecentPagesWidget` provides plus a "New Project" action.

- [ ] **Step 1: Create the file**

Create `lib/features/projects/presentation/pages/recent_activity_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/project/project_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/recent_pages_widget.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/runs_list_widget.dart';

class RecentActivityPage extends StatefulWidget {
  const RecentActivityPage({super.key});

  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseBackground,
      body: Column(
        children: [
          _TopBar(onNewProject: _handleNewProject),
          Expanded(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: recent activity
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.sidebarBackground,
                        borderRadius: AppRadius.br6,
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: AppSpacing.pagePadding,
                      child: const RecentPagesWidget(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Right: recent runs
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.sidebarBackground,
                        borderRadius: AppRadius.br6,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.br6,
                        child: const RunsListWidget(flowId: null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNewProject() {
    ProjectDialogs.showCreateDialog(
      context,
      onCreate: (name, description) async {
        final project = await context.read<ProjectProvider>().createProject(
          name: name,
          description: description,
        );
        await context.read<ProjectProvider>().selectProject(project);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/workspace');
        }
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onNewProject;

  const _TopBar({required this.onNewProject});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Text('StressPilot', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          _NewProjectButton(onPressed: onNewProject),
        ],
      ),
    );
  }
}

class _NewProjectButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _NewProjectButton({required this.onPressed});

  @override
  State<_NewProjectButton> createState() => _NewProjectButtonState();
}

class _NewProjectButtonState extends State<_NewProjectButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.accentHover : AppColors.accent,
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, size: 14, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text('New Project', style: AppTypography.body),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run:
```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/projects/presentation/pages/recent_activity_page.dart
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/projects/presentation/pages/recent_activity_page.dart
git commit -m "feat: add RecentActivityPage as Fleet-styled landing screen"
```

---

### Task 3: Update router — route projectsRoute to RecentActivityPage, remove projectEndpointsRoute

**Files:**
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/features/projects/presentation/widgets/recent_pages_widget.dart`

`projectEndpointsRoute` is being removed because endpoints now live in the workspace sidebar+tabs. `RecentPagesWidget` currently uses it for endpoint taps — update to navigate to workspace instead.

- [ ] **Step 1: Update app_router.dart**

In `lib/core/navigation/app_router.dart`:

1. Add import for `RecentActivityPage`:
```dart
import 'package:stress_pilot/features/projects/presentation/pages/recent_activity_page.dart';
```

2. Remove the `projectEndpointsRoute` constant and its route case.

3. Change the `workspaceRoute` guard to use `RecentActivityPage`:
```dart
if (settings.name == workspaceRoute) {
  final projectProvider = getIt<ProjectProvider>();
  if (projectProvider.selectedProject == null) {
    return buildRoute(const RecentActivityPage());
  }
}
```

4. Change the `projectsRoute` case:
```dart
case projectsRoute:
  return buildRoute(const RecentActivityPage());
```

The full `generateRoute` switch after this change:
```dart
static Route<dynamic> generateRoute(RouteSettings settings) {
  MaterialPageRoute<T> buildRoute<T>(Widget widget) {
    return MaterialPageRoute<T>(builder: (_) => widget, settings: settings);
  }

  if (settings.name == workspaceRoute) {
    final projectProvider = getIt<ProjectProvider>();
    if (projectProvider.selectedProject == null) {
      return buildRoute(const RecentActivityPage());
    }
  }

  switch (settings.name) {
    case projectsRoute:
      return buildRoute(const RecentActivityPage());
    case workspaceRoute:
      return buildRoute(const ProjectWorkspacePage());
    case settingsRoute:
      return buildRoute(const SettingsPage());
    case projectEnvironmentRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return buildRoute(
        EnvironmentPage(
          environmentId: args['environmentId'],
          projectName: args['projectName'],
        ),
      );
    case resultsRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return buildRoute(ResultsPage(runId: args['runId'] as String));
    case marketplaceRoute:
      return buildRoute(const MarketplacePage());
    case agentRoute:
      return buildRoute(const AgentPage());
    default:
      return buildRoute(
        Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      );
  }
}
```

Also remove the `projectEndpointsRoute` constant declaration and its import of `ProjectEndpointsPage` and `Endpoint`.

- [ ] **Step 2: Update recent_pages_widget.dart endpoint tap**

In `lib/features/projects/presentation/widgets/recent_pages_widget.dart`, change the `RecentEntityType.endpoint` case:

Old:
```dart
case RecentEntityType.endpoint:
  final project = Project.fromJson(item.arguments['project'] as Map<String, dynamic>);
  await projectProvider.selectProject(project);
  AppNavigator.pushNamed(
    AppRouter.projectEndpointsRoute,
    arguments: item.arguments,
  );
  break;
```

New:
```dart
case RecentEntityType.endpoint:
  final project = Project.fromJson(item.arguments['project'] as Map<String, dynamic>);
  await projectProvider.selectProject(project);
  AppNavigator.pushReplacementNamed(AppRouter.workspaceRoute);
  break;
```

- [ ] **Step 3: Verify**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/core/navigation/app_router.dart lib/features/projects/presentation/widgets/recent_pages_widget.dart
```
Expected: no errors (no reference to projectEndpointsRoute, no ProjectEndpointsPage import needed)

- [ ] **Step 4: Commit**

```bash
git add lib/core/navigation/app_router.dart lib/features/projects/presentation/widgets/recent_pages_widget.dart
git commit -m "refactor: replace projects landing with RecentActivityPage, remove endpoint standalone route"
```

---

### Task 4: Wire endpoint and flow CRUD in workspace sidebar

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

The sidebar has a TODO in `_SidebarSection.onAdd`. Wire create dialogs for endpoints and flows, and add hover edit/delete icon buttons to each row.

- [ ] **Step 1: Add imports to workspace_sidebar.dart**

At the top of `lib/features/projects/presentation/widgets/workspace_sidebar.dart`, ensure these imports are present (add any missing):

```dart
import 'package:stress_pilot/features/endpoints/presentation/widgets/create_endpoint_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/widgets/flow_dialog.dart';
import 'package:stress_pilot/features/projects/presentation/provider/project_provider.dart';
import 'package:stress_pilot/core/themes/components/components.dart';
```

- [ ] **Step 2: Wire _SidebarSection onAdd**

Replace the `_SidebarSection` widget's `_SidebarSectionState.build` method. The `_SectionHeader` `onAdd` callback should open the correct dialog based on section type:

```dart
@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeader(
        title: widget.title,
        isExpanded: _isExpanded,
        onToggle: () => setState(() => _isExpanded = !_isExpanded),
        onAdd: () => _handleAdd(context),
      ),
      if (_isExpanded) ...[
        if (widget.type == _SectionType.endpoints)
          const _EndpointList()
        else
          const _FlowList(),
      ],
    ],
  );
}

void _handleAdd(BuildContext context) {
  if (widget.type == _SectionType.endpoints) {
    final projectId = context.read<ProjectProvider>().selectedProject?.id;
    if (projectId == null) return;
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<EndpointProvider>(),
        child: CreateEndpointDialog(projectId: projectId),
      ),
    );
  } else {
    FlowDialog.showCreateDialog(
      context,
      onCreate: (name, description, type, projectId) async {
        await context.read<FlowProvider>().createFlow(
          flow_domain.CreateFlowRequest(
            name: name,
            description: description,
            type: type,
            projectId: projectId,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Add edit/delete hover actions to _EndpointRow**

Replace the `_EndpointRowState.build` method to show edit/delete icons on hover:

```dart
@override
Widget build(BuildContext context) {
  final method = widget.endpoint.httpMethod ?? 'GET';
  final methodColor = _getMethodColor(method);

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
            _MethodBadge(method: method, color: methodColor),
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
              _IconButton(
                icon: LucideIcons.pencil,
                onTap: () => widget.onEdit(),
              ),
              _IconButton(
                icon: LucideIcons.trash2,
                onTap: () => widget.onDelete(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
```

Update `_EndpointRow` to accept `onEdit` and `onDelete` callbacks:

```dart
class _EndpointRow extends StatefulWidget {
  final Endpoint endpoint;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EndpointRow({
    required this.endpoint,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EndpointRow> createState() => _EndpointRowState();
}
```

- [ ] **Step 4: Wire endpoint edit and delete from _EndpointList**

Update `_EndpointList.build` to pass edit/delete handlers:

```dart
@override
Widget build(BuildContext context) {
  final endpointProvider = context.watch<EndpointProvider>();
  final endpoints = endpointProvider.endpoints;
  final selectedEndpoint = endpointProvider.selectedEndpoint;

  return Column(
    children: endpoints.map((e) => _EndpointRow(
      endpoint: e,
      isSelected: selectedEndpoint?.id == e.id,
      onTap: () {
        endpointProvider.selectEndpoint(e);
        context.read<WorkspaceTabProvider>().openTab(
          WorkspaceTab(
            id: 'endpoint_${e.id}',
            name: e.name,
            type: WorkspaceTabType.endpoint,
            data: e,
          ),
        );
      },
      onEdit: () {
        final projectId = context.read<ProjectProvider>().selectedProject?.id;
        if (projectId == null) return;
        showDialog(
          context: context,
          builder: (_) => ChangeNotifierProvider.value(
            value: endpointProvider,
            child: CreateEndpointDialog(
              projectId: projectId,
              endpoint: e,
            ),
          ),
        );
      },
      onDelete: () {
        final projectId = context.read<ProjectProvider>().selectedProject?.id;
        if (projectId == null) return;
        PilotDialog.show(
          context: context,
          title: 'Delete Endpoint',
          content: Text(
            'Delete "${e.name}"? This cannot be undone.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await endpointProvider.deleteEndpoint(e.id, projectId);
              },
              child: Text('Delete', style: AppTypography.body.copyWith(color: AppColors.error)),
            ),
          ],
        );
      },
    )).toList(),
  );
}
```

- [ ] **Step 5: Add edit/delete hover actions to _FlowRow**

Update `_FlowRow` to accept `onEdit` and `onDelete`:

```dart
class _FlowRow extends StatefulWidget {
  final flow_domain.Flow flow;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlowRow({
    required this.flow,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FlowRow> createState() => _FlowRowState();
}
```

Update `_FlowRowState.build` to show edit/delete on hover:

```dart
@override
Widget build(BuildContext context) {
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
            Icon(
              LucideIcons.gitFork,
              size: 14,
              color: widget.isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.flow.name,
                style: AppTypography.body.copyWith(
                  color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isHovered) ...[
              _IconButton(
                icon: LucideIcons.pencil,
                onTap: () => widget.onEdit(),
              ),
              _IconButton(
                icon: LucideIcons.trash2,
                onTap: () => widget.onDelete(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 6: Wire flow edit and delete from _FlowList**

Update `_FlowList.build`:

```dart
@override
Widget build(BuildContext context) {
  final flowProvider = context.watch<FlowProvider>();
  final flows = flowProvider.flows;
  final selectedFlow = flowProvider.selectedFlow;

  return Column(
    children: flows.map((f) => _FlowRow(
      flow: f,
      isSelected: selectedFlow?.id == f.id,
      onTap: () {
        flowProvider.selectFlow(f);
        context.read<WorkspaceTabProvider>().openTab(
          WorkspaceTab(
            id: 'flow_${f.id}',
            name: f.name,
            type: WorkspaceTabType.flow,
            data: f,
          ),
        );
      },
      onEdit: () {
        FlowDialog.showEditDialog(
          context,
          flow: f,
          onUpdate: (id, name, description) async {
            await flowProvider.updateFlow(flowId: id, name: name, description: description);
          },
        );
      },
      onDelete: () {
        PilotDialog.show(
          context: context,
          title: 'Delete Flow',
          content: Text(
            'Delete "${f.name}"? This cannot be undone.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await flowProvider.deleteFlow(f.id);
              },
              child: Text('Delete', style: AppTypography.body.copyWith(color: AppColors.error)),
            ),
          ],
        );
      },
    )).toList(),
  );
}
```

> **Note:** If `FlowDialog.showEditDialog` does not exist, add it to `flow_dialog.dart` mirroring `showCreateDialog` but pre-filling name/description and calling `FlowRepository.updateFlow`. Check the file first — if only `showCreateDialog` exists, add `showEditDialog` to the same class.

- [ ] **Step 7: Verify**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/projects/presentation/widgets/workspace_sidebar.dart
```
Expected: no errors

- [ ] **Step 8: Commit**

```bash
git add lib/features/projects/presentation/widgets/workspace_sidebar.dart
git commit -m "feat: wire endpoint and flow CRUD from workspace sidebar"
```

---

### Task 5: Add environment badge to workspace

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`

The environment badge sits below the nav bar, top-right of the content area. It shows the project's environment ID and navigates to the environment page.

- [ ] **Step 1: Add _EnvBadge widget to project_workspace_page.dart**

Add this private widget at the bottom of `lib/features/projects/presentation/pages/project_workspace_page.dart`:

```dart
class _EnvBadge extends StatefulWidget {
  final int environmentId;
  final String projectName;

  const _EnvBadge({required this.environmentId, required this.projectName});

  @override
  State<_EnvBadge> createState() => _EnvBadgeState();
}

class _EnvBadgeState extends State<_EnvBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.hoverItem : AppColors.elevatedSurface,
            borderRadius: AppRadius.br4,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.settings2, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'ENV',
                style: AppTypography.codeSm.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add env badge to workspace layout**

In `ProjectWorkspacePage.build`, update the content area to include the env badge row above the tab bar. The `_buildTabContent` stays the same. Update the `Column` inside `Expanded` (after sidebar row):

```dart
Expanded(
  child: Container(
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: AppColors.divider)),
    ),
    child: Column(
      children: [
        // Env badge bar — only shown when project has environment
        if (project != null && project.environmentId != 0)
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _EnvBadge(
                  environmentId: project.environmentId,
                  projectName: project.name,
                ),
              ],
            ),
          ),
        const WorkspaceTabBar(),
        Expanded(
          child: _buildTabContent(activeTab),
        ),
      ],
    ),
  ),
),
```

Read `project` from `context.watch<ProjectProvider>().selectedProject` at top of `build`.

- [ ] **Step 3: Verify**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/projects/presentation/pages/project_workspace_page.dart
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "feat: add environment badge to workspace content area"
```

---

### Task 6: Fleet token pass — settings page

**Files:**
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`

Re-skin the settings page to Fleet tokens: Fleet background colors, no shadows, Fleet density, token-referenced spacing.

- [ ] **Step 1: Read the current settings_page.dart**

Read `lib/features/settings/presentation/pages/settings_page.dart` fully to understand current structure before editing.

- [ ] **Step 2: Apply Fleet token pass**

In `settings_page.dart`:
- Set `Scaffold.backgroundColor` to `AppColors.baseBackground`
- Replace any `Color(0x...)` or hardcoded hex with `AppColors.*` tokens
- Remove all `BoxDecoration` that contains `boxShadow`
- Replace any `BorderRadius.circular(n)` where n > 8 with `AppRadius.br6` or `AppRadius.br8`
- Replace `Colors.white`, `Colors.black`, `Colors.grey*` with the appropriate `AppColors.*` token
- Set section headers to `AppTypography.label` (11px, uppercase, secondary)
- Set body text to `AppTypography.body` (13px, primary)

- [ ] **Step 3: Verify**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/settings/presentation/pages/settings_page.dart lib/features/settings/presentation/widgets/
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/presentation/pages/settings_page.dart lib/features/settings/presentation/widgets/
git commit -m "style: fleet token pass on settings page"
```

---

### Task 7: Fleet token pass — marketplace page

**Files:**
- Modify: `lib/features/marketplace/presentation/pages/marketplace_page.dart`

- [ ] **Step 1: Read current marketplace_page.dart**

Read `lib/features/marketplace/presentation/pages/marketplace_page.dart` fully.

- [ ] **Step 2: Apply Fleet token pass**

Apply same rules as Task 6:
- `Scaffold.backgroundColor` = `AppColors.baseBackground`
- Plugin cards: `color: AppColors.sidebarBackground`, `borderRadius: AppRadius.br6`, no shadows
- Card borders: `Border.all(color: AppColors.border)`
- Card titles: `AppTypography.heading`
- Card bodies: `AppTypography.body` with `color: AppColors.textSecondary`
- Remove all `boxShadow` entries

- [ ] **Step 3: Verify**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/marketplace/presentation/pages/marketplace_page.dart
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/marketplace/presentation/pages/marketplace_page.dart
git commit -m "style: fleet token pass on marketplace page"
```

---

### Task 8: Fleet token pass — environment page

**Files:**
- Modify: `lib/features/environments/presentation/pages/environment_page.dart`
- Modify: `lib/features/environments/presentation/widgets/environment_table.dart`
- Modify: `lib/features/environments/presentation/widgets/environment_dialog.dart`

- [ ] **Step 1: Read the environment page and its widgets**

Read each file fully:
- `lib/features/environments/presentation/pages/environment_page.dart`
- `lib/features/environments/presentation/widgets/environment_table.dart`
- `lib/features/environments/presentation/widgets/environment_dialog.dart`

- [ ] **Step 2: Apply Fleet token pass to environment_page.dart**

- `Scaffold.backgroundColor` = `AppColors.baseBackground`
- Table background: `AppColors.sidebarBackground`
- No shadows
- Borders use `AppColors.border`
- Typography tokens throughout

- [ ] **Step 3: Apply Fleet token pass to environment_table.dart**

- Table header row: `AppColors.elevatedSurface` background, `AppTypography.label` text
- Table rows: 32px height, `AppColors.hoverItem` on hover
- Input cells: `AppColors.elevatedSurface` bg, `AppColors.border` border

- [ ] **Step 4: Apply Fleet token pass to environment_dialog.dart**

- Dialog background: `AppColors.elevatedSurface`
- Title: `AppTypography.heading`
- Body: `AppTypography.body` with `AppColors.textSecondary`
- Actions: text buttons only, no filled button bar

- [ ] **Step 5: Verify**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/environments/
```
Expected: no errors

- [ ] **Step 6: Commit**

```bash
git add lib/features/environments/
git commit -m "style: fleet token pass on environment page and widgets"
```

---

### Task 9: Remove dead code and final cleanup

**Files:**
- Modify: `lib/features/projects/presentation/pages/projects_page.dart` — check if used anywhere still
- Modify: `lib/core/navigation/app_router.dart` — confirm projectEndpointsRoute removed

- [ ] **Step 1: Check if ProjectsPage is still referenced**

```bash
grep -rn "ProjectsPage\|projectsRoute\|ProjectEndpointsPage" /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app/lib/ --include="*.dart"
```

Expected: `projectsRoute` used in router (pointing to RecentActivityPage), no `ProjectEndpointsPage` references.

If `ProjectsPage` still has no callers, delete or comment out the old class to reduce dead code. If it IS still used somewhere, leave it.

- [ ] **Step 2: Final analyze pass**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/
```
Expected: no errors (warnings about unused imports are fine to fix)

- [ ] **Step 3: Fix any remaining unused import warnings**

For each file with "unused import" warnings from step 2, remove the flagged import.

- [ ] **Step 4: Commit**

```bash
git add -p
git commit -m "chore: remove dead code, clean unused imports"
```

---

## Self-Review: Spec Coverage

| Spec requirement | Task that covers it |
|-----------------|---------------------|
| Launch flow: saved project → workspace | Already done in app_root.dart |
| Launch flow: no saved project → Recent Activity | Task 2, 3 |
| Workspace: Fleet sidebar with endpoints list | Already done |
| Workspace: Fleet sidebar with flows list | Already done |
| Workspace: nav bar (project name, Marketplace, Settings, Agent) | Already done |
| Workspace: tab bar (Fleet-style, accent bottom border) | Already done |
| Sidebar: CRUD endpoints (add, edit, delete) | Task 4 |
| Sidebar: CRUD flows (add, edit, delete) | Task 4 |
| Environment badge top-right of content area | Task 5 |
| Recent Activity screen (dark list, secondary timestamps) | Task 2 |
| Settings page token pass | Task 6 |
| Marketplace/Plugins token pass | Task 7 |
| Env var management token pass | Task 8 |
| Remove standalone Endpoint Management route | Task 3 |
| Remove Project landing page as standalone | Task 3 |
| Remove boxShadow everywhere | Token aliases cap radius; Task 6-8 remove shadows |
| Token file with all values | Already done + Task 1 (aliases) |

**Gaps checked:** None found. All spec sections covered.

**Placeholder scan:** No TBD, no "fill in later", all code blocks are complete.

**Type consistency check:**
- `FlowDialog.showEditDialog` — check if it exists before Task 4; if not, add it to `flow_dialog.dart` first
- `CreateEndpointDialog(endpoint: e)` — check if it accepts an optional `endpoint` param for edit mode; if not, the edit action in Task 4 should open the endpoint editor tab instead of a dialog
- `endpointProvider.selectedEndpoint` — used in sidebar but check the actual getter name in `EndpointProvider`
- `AppColors.error` — defined in `theme_tokens.dart` as `Color(0xFFD2504B)` ✓
- `AppColors.elevatedSurface` — defined in `theme_tokens.dart` ✓
- `AppRouter.projectEnvironmentRoute` — defined in router, stays in place ✓

**Pre-implementation checks required (do before starting Task 4):**
1. Check if `FlowDialog.showEditDialog` exists: `grep -n "showEditDialog" lib/features/projects/presentation/widgets/flow_dialog.dart`
2. Check if `CreateEndpointDialog` accepts an `endpoint` param: `grep -n "endpoint" lib/features/endpoints/presentation/widgets/create_endpoint_dialog.dart | head -10`
3. Check `EndpointProvider.selectedEndpoint` getter name: `grep -n "selectedEndpoint\|_selectedEndpoint" lib/features/endpoints/presentation/provider/endpoint_provider.dart`
