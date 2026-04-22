# Nav Icons, Fleet Page Bar & IntelliJ Run Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace text nav labels with icon buttons with tooltips, replace the old floating `AppTopBar` across all pages with a flat Fleet-style `FleetPageBar`, and make the play button look like an IntelliJ-style green run button.

**Architecture:** Three independent changes — (1) workspace nav bar icons, (2) a new shared `FleetPageBar` widget applied to all secondary pages, (3) a more prominent play/stop button. All are pure presentation changes that use existing providers and routing. No logic changes.

**Tech Stack:** Flutter, shadcn_ui (LucideIcons, ShadTooltip), google_fonts (Montserrat via AppTypography), existing AppColors/AppRadius/AppSpacing/AppDurations tokens.

**Note:** Keymaps (`SHORTCUTS` tab) and theming (`THEME` tab) already exist in Settings and are fully functional. Nothing to implement there.

**Quality gate (mandatory after every task):**
```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/
```
Zero errors before every commit.

---

## Key context

### WorkspaceNavBar (current)
`lib/features/projects/presentation/widgets/workspace_nav_bar.dart`
- Left: `_ProjectNameButton` (clickable project picker ✅ already done)
- Right: `_NavButton(label: 'Marketplace', ...)`, `_NavDivider()`, `_NavButton(label: 'Settings', ...)`, `_NavDivider()`, `_NavButton(label: 'Agent', ...)` — text only, no icons

### AppTopBar (old, to replace)
`lib/features/shared/presentation/widgets/app_topbar.dart`
- Floating 60px rounded bar with margin — used in 7 places:
  - `lib/features/marketplace/presentation/pages/marketplace_page.dart`
  - `lib/features/settings/presentation/pages/settings_page.dart`
  - `lib/features/results/presentation/pages/results_page.dart`
  - `lib/features/agent/presentation/pages/agent_page.dart`
  - `lib/features/environments/presentation/pages/environment_page.dart`
  - `lib/features/endpoints/presentation/pages/endpoints_page.dart`
  - `lib/features/projects/presentation/pages/projects_page.dart`

### _PlayStopButton (current)
`lib/features/projects/presentation/pages/project_workspace_page.dart` — small icon-only 28×24 button. Needs to be an IntelliJ-style filled green button.

---

## File Map

| File | Action | What changes |
|------|--------|-------------|
| `lib/features/projects/presentation/widgets/workspace_nav_bar.dart` | Modify | Replace text `_NavButton` with icon `_NavIconButton` (LucideIcons + ShadTooltip) |
| `lib/features/shared/presentation/widgets/fleet_page_bar.dart` | **Create** | New reusable flat Fleet-style page bar (back button + title + right actions) |
| `lib/features/marketplace/presentation/pages/marketplace_page.dart` | Modify | Replace `AppTopBar()` with `FleetPageBar` |
| `lib/features/settings/presentation/pages/settings_page.dart` | Modify | Replace `AppTopBar()` with `FleetPageBar` |
| `lib/features/results/presentation/pages/results_page.dart` | Modify | Replace `AppTopBar()` with `FleetPageBar` |
| `lib/features/agent/presentation/pages/agent_page.dart` | Modify | Replace `AppTopBar()` with `FleetPageBar` |
| `lib/features/environments/presentation/pages/environment_page.dart` | Modify | Replace `AppTopBar()` with `FleetPageBar` |
| `lib/features/endpoints/presentation/pages/endpoints_page.dart` | Modify | Replace `AppTopBar()` with `FleetPageBar` |
| `lib/features/projects/presentation/pages/projects_page.dart` | Modify | Replace `AppTopBar()` with `FleetPageBar` |
| `lib/features/projects/presentation/pages/project_workspace_page.dart` | Modify | Replace `_PlayStopButton` icon-only with IntelliJ-style filled button |

---

## Task 1: Nav bar — icons with tooltips

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`

Replace the text `_NavButton` / `_NavDivider` widgets with icon buttons that show a tooltip on hover. Use `ShadTooltip` (from `shadcn_ui`) for Fleet-consistent tooltip styling.

- [ ] **Step 1: Read workspace_nav_bar.dart**

Read the full file. Note the `_NavButton` class (text label, hover accent color) and `_NavDivider` class (dot separator). Also confirm `import 'package:shadcn_ui/shadcn_ui.dart'` is present.

- [ ] **Step 2: Replace _NavButton and _NavDivider with _NavIconButton**

In `WorkspaceNavBar.build`, replace:
```dart
_NavButton(
  label: 'Marketplace',
  onPressed: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
),
_NavDivider(),
_NavButton(
  label: 'Settings',
  onPressed: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
),
_NavDivider(),
_NavButton(
  label: 'Agent',
  onPressed: () => AppNavigator.pushNamed(AppRouter.agentRoute),
),
```

With:
```dart
_NavIconButton(
  icon: LucideIcons.shoppingBag,
  tooltip: 'Marketplace',
  onPressed: () => AppNavigator.pushNamed(AppRouter.marketplaceRoute),
),
const SizedBox(width: 4),
_NavIconButton(
  icon: LucideIcons.settings,
  tooltip: 'Settings',
  onPressed: () => AppNavigator.pushNamed(AppRouter.settingsRoute),
),
const SizedBox(width: 4),
_NavIconButton(
  icon: LucideIcons.sparkles,
  tooltip: 'Agent',
  onPressed: () => AppNavigator.pushNamed(AppRouter.agentRoute),
),
```

- [ ] **Step 3: Add _NavIconButton class**

Delete the `_NavButton` and `_NavDivider` classes. Add `_NavIconButton` at the bottom of the file (before `_ProjectNameButton`):

```dart
class _NavIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ShadTooltip(
      builder: (context) => Text(
        widget.tooltip,
        style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.hoverItem : Colors.transparent,
              borderRadius: AppRadius.br4,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _isHovered ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Analyze**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/projects/presentation/widgets/workspace_nav_bar.dart
```
Expected: zero errors.

- [ ] **Step 5: Commit**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app
git add lib/features/projects/presentation/widgets/workspace_nav_bar.dart
git commit -m "style: replace nav bar text labels with icon buttons with tooltips"
```

---

## Task 2: Create FleetPageBar shared widget

**Files:**
- Create: `lib/features/shared/presentation/widgets/fleet_page_bar.dart`

A flat, consistent top bar for all secondary pages (Settings, Results, Marketplace, etc.). It replaces the old floating `AppTopBar`. Same height as `WorkspaceNavBar` (`AppSpacing.navBarHeight`), same bottom border, same background.

- [ ] **Step 1: Check AppSpacing.navBarHeight**

Read `lib/core/themes/theme_tokens.dart` and find `AppSpacing.navBarHeight`. Note the value (likely 40 or 44).

- [ ] **Step 2: Create fleet_page_bar.dart**

Create `lib/features/shared/presentation/widgets/fleet_page_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stress_pilot/core/themes/theme_tokens.dart';

/// Flat Fleet-style page bar for secondary pages.
/// Replaces the old floating AppTopBar.
class FleetPageBar extends StatelessWidget {
  /// Page title shown in the center-left area.
  final String title;

  /// Optional widgets placed on the right side of the bar.
  final List<Widget> actions;

  /// Whether to show a back button (default true).
  final bool showBack;

  /// Custom back action. If null, uses Navigator.of(context).pop().
  final VoidCallback? onBack;

  const FleetPageBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.baseBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _BackButton(onTap: onBack ?? () => Navigator.of(context).pop()),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '/',
              style: AppTypography.body.copyWith(color: AppColors.textDisabled),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            title,
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: AppRadius.br4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.chevronLeft,
                size: 16,
                color: _hovered ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                'Back',
                style: AppTypography.body.copyWith(
                  color: _hovered ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/shared/presentation/widgets/fleet_page_bar.dart
```
Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app
git add lib/features/shared/presentation/widgets/fleet_page_bar.dart
git commit -m "feat: add FleetPageBar shared widget for secondary pages"
```

---

## Task 3: Replace AppTopBar in all secondary pages

**Files:**
- Modify: `lib/features/marketplace/presentation/pages/marketplace_page.dart`
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`
- Modify: `lib/features/results/presentation/pages/results_page.dart`
- Modify: `lib/features/agent/presentation/pages/agent_page.dart`
- Modify: `lib/features/environments/presentation/pages/environment_page.dart`
- Modify: `lib/features/endpoints/presentation/pages/endpoints_page.dart`
- Modify: `lib/features/projects/presentation/pages/projects_page.dart`

For each file:
1. Add import: `import 'package:stress_pilot/features/shared/presentation/widgets/fleet_page_bar.dart';`
2. Remove import: `import 'package:stress_pilot/features/shared/presentation/widgets/app_topbar.dart';` (or from layout.dart)
3. Replace `const AppTopBar()` (or `AppTopBar(...)`) with `FleetPageBar(title: '<PageTitle>')`
4. Remove any existing inner title/back-button header that was inside the page content (since AppTopBar was standalone and some pages had their own inner header too)

**Important per-page notes:**

### marketplace_page.dart
- Remove `const AppTopBar()` from the Column
- Remove `margin: const EdgeInsets.fromLTRB(16, 0, 16, 16)` on the content container (AppTopBar had a floating style with margins; FleetPageBar is flat and full-width, so the content should go edge-to-edge below it)
- Replace with `const FleetPageBar(title: 'Marketplace')`
- The page has a manual back button inside the webview stack — keep it as-is

### settings_page.dart
- Remove `const AppTopBar()` from the Column
- Remove the inner 60px header Container (the one with back button + "Settings" text) — `FleetPageBar` now provides both
- Remove `margin: const EdgeInsets.fromLTRB(16, 0, 16, 16)` from the content Container
- Replace with `const FleetPageBar(title: 'Settings')`

### results_page.dart
- Read the file carefully. Note the `AppTopBar()` line and any inner title bar
- Remove `const AppTopBar()` (or `AppTopBar()`)
- Remove any inner title row at the top of the results content
- Replace with `FleetPageBar(title: 'Results', actions: [/* export button if there is one */])`
- Keep all result metrics, charts, etc. unchanged

### agent_page.dart
- Remove `const AppTopBar()`
- Replace with `const FleetPageBar(title: 'Agent')`

### environment_page.dart
- Read the file. It likely has an inner header too
- Remove `const AppTopBar()`
- Remove any inner duplicate header
- Replace with `FleetPageBar(title: 'Environment')`

### endpoints_page.dart
- Remove `const AppTopBar()`
- Replace with `const FleetPageBar(title: 'Endpoints')`

### projects_page.dart
- Remove `AppTopBar(...)` (it may have params)
- Replace with `const FleetPageBar(title: 'Projects', showBack: false)` — projects page has no logical "back" page

- [ ] **Step 1: Read all 7 files**

Read each file fully before modifying. Note:
- Where `AppTopBar` appears in the Column
- Whether there is an inner header/title bar in the page content area
- The margin on the content Container (remove if it was sized for floating AppTopBar)

- [ ] **Step 2: Apply changes to marketplace_page.dart**

After reading: replace `const AppTopBar()` with `const FleetPageBar(title: 'Marketplace')`. Remove floating margin from content Container.

- [ ] **Step 3: Apply changes to settings_page.dart**

After reading: replace `const AppTopBar()` with `const FleetPageBar(title: 'Settings')`. Remove the inner 60px title Container (lines ~46–66 in the current file — the Container with height 60 that shows back button + "Settings" text). Remove floating margin from content Container.

- [ ] **Step 4: Apply changes to results_page.dart**

Read the file carefully (it's 636 lines). Find `AppTopBar()` call and any inner title bar near the top of the results layout. Replace with `FleetPageBar(title: 'Results')`. If there's an export button, pass it as:
```dart
FleetPageBar(
  title: 'Results',
  actions: [
    // move any existing action buttons here as widgets
  ],
)
```

- [ ] **Step 5: Apply changes to agent_page.dart, environment_page.dart, endpoints_page.dart, projects_page.dart**

For each: replace `AppTopBar()` with the appropriate `FleetPageBar(title: '...')`. Remove inner duplicate headers if present.

- [ ] **Step 6: Analyze**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/
```
Expected: zero errors. Fix any remaining `AppTopBar` import errors.

- [ ] **Step 7: Commit**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app
git add lib/features/marketplace/presentation/pages/marketplace_page.dart \
        lib/features/settings/presentation/pages/settings_page.dart \
        lib/features/results/presentation/pages/results_page.dart \
        lib/features/agent/presentation/pages/agent_page.dart \
        lib/features/environments/presentation/pages/environment_page.dart \
        lib/features/endpoints/presentation/pages/endpoints_page.dart \
        lib/features/projects/presentation/pages/projects_page.dart
git commit -m "refactor: replace AppTopBar with FleetPageBar across all secondary pages"
```

---

## Task 4: IntelliJ-style run button

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`

The current `_PlayStopButton` is a tiny 28×24 icon-only button. Make it look like IntelliJ's green run button: a rounded pill with a colored background, icon, and optional label. When stopped → green filled pill. When executing → red/orange filled pill. When disabled → muted, no fill.

- [ ] **Step 1: Read _PlayStopButton in project_workspace_page.dart**

Read `lib/features/projects/presentation/pages/project_workspace_page.dart`, focusing on `_PlayStopButton` and `_PlayStopButtonState`. Note the current size (28×24), colors, icon logic.

- [ ] **Step 2: Replace icon-only container with pill button**

In `_PlayStopButtonState.build`, replace the current `AnimatedContainer(width: 28, height: 24, ...)` with a pill-style button:

```dart
@override
Widget build(BuildContext context) {
  final endpointProvider = context.watch<EndpointProvider>();

  final endpoint = _isEndpoint ? widget.activeTab!.data as Endpoint : null;
  final isExecuting = endpoint != null && endpointProvider.isEndpointExecuting(endpoint.id);

  final bool canAct = widget.activeTab != null && widget.project != null;

  final IconData icon = isExecuting ? LucideIcons.squareStop : LucideIcons.play;

  final Color fillColor = !canAct
      ? AppColors.textDisabled.withValues(alpha: 0.15)
      : isExecuting
          ? AppColors.error.withValues(alpha: 0.15)
          : AppColors.methodGet.withValues(alpha: 0.15);

  final Color iconColor = !canAct
      ? AppColors.textDisabled
      : isExecuting
          ? AppColors.error
          : AppColors.methodGet;

  final String label = isExecuting ? 'Stop' : (_isFlow ? 'Run Flow' : 'Run');

  final String tooltip = isExecuting
      ? 'Stop execution'
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered && canAct
                ? fillColor.withValues(alpha: fillColor.a * 2)
                : fillColor,
            borderRadius: AppRadius.br4,
            border: Border.all(
              color: iconColor.withValues(alpha: canAct ? 0.4 : 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.codeSm.copyWith(color: iconColor),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

The `_handleTap` method is unchanged.

- [ ] **Step 3: Analyze**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app && flutter analyze lib/features/projects/presentation/pages/project_workspace_page.dart
```
Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
cd /home/longlh20/Workspace/wasted/StressPilot/stresspilot_super_app
git add lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "style: IntelliJ-style filled pill run/stop button"
```

---

## Self-Review: Spec Coverage

| User requirement | Task |
|----------------|------|
| Icons with tooltips on hover (Marketplace, Settings, Agent) | Task 1 |
| Remove old floating AppTopBar | Task 3 |
| Consistent page bar across all pages | Tasks 2 + 3 |
| Action button like IntelliJ run button | Task 4 |
| Project dropdown when clicking workspace project name | ✅ Already done (prev plan Task 3) |
| Keymaps customizable | ✅ Already in Settings > SHORTCUTS tab |
| Theme customizable | ✅ Already in Settings > THEME tab |

**Placeholder scan:** No TBD or placeholder language found.

**Type consistency:**
- `FleetPageBar(title: String, actions: List<Widget>, showBack: bool, onBack: VoidCallback?)` — defined in Task 2, used in Task 3 ✓
- `_NavIconButton(icon: IconData, tooltip: String, onPressed: VoidCallback)` — defined and used in Task 1 ✓
- `AppRadius.br4`, `AppColors.methodGet`, `AppColors.error` — all exist in theme_tokens.dart ✓
- `LucideIcons.shoppingBag`, `.settings`, `.sparkles`, `.chevronLeft` — all valid LucideIcons ✓
