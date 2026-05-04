# Global UI Refinement & Fleet Islands Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the application UI under the JetBrains Fleet "Islands" aesthetic, fix dark mode color inconsistencies, and standardize theme token usage across all features.

**Architecture:** We will enhance the `PilotPanel` component to be the primary building block for "Islands". All major feature pages will be refactored to use this standardized panel for their main content areas. We will also audit sidebars and floating toolbars to ensure consistent background colors and glassmorphism effects.

**Tech Stack:** Flutter, Provider, Theme Tokens

---

### Task 1: Enhance PilotPanel for Global Use

**Files:**
- Modify: `lib/core/themes/components/layout/pilot_panel.dart`

- [ ] **Step 1: Add flexible styling options to PilotPanel**
Update `PilotPanel` to support different background colors, border visibility, and shadow configurations. This will allow it to be used for both main islands and sub-cards.

```dart
// lib/core/themes/components/layout/pilot_panel.dart
class PilotPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool showBorder;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  const PilotPanel({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.showBorder = true,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.br12;
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.baseBackground,
        borderRadius: radius,
        border: showBorder ? Border.all(color: AppColors.border) : null,
        boxShadow: boxShadow ?? AppShadows.panel,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 2: Verify component**
Ensure no compilation errors in existing usages (e.g., `EnvironmentPage`).

---

### Task 2: Standardize Workspace Page & Tab Bar

**Files:**
- Modify: `lib/features/workspace/presentation/pages/workspace_page.dart`
- Modify: `lib/features/workspace/presentation/widgets/workspace_tab_bar.dart`

- [ ] **Step 1: Use PilotPanel for Workspace main island**
Refactor the main content area to use the enhanced `PilotPanel`.

- [ ] **Step 2: Unify WorkspaceTabBar background**
Change `WorkspaceTabBar` background from `AppColors.sidebarBackground` to `Colors.transparent` so it inherits the island's background. Remove the hardcoded height container if necessary to allow the island padding to control spacing.

- [ ] **Step 3: Fix WorkspaceSidebar background**
Ensure the sidebar uses `AppColors.sidebarBackground` but has a consistent border with the island.

---

### Task 3: Fix Canvas Toolbars & Dark Mode Error

**Files:**
- Modify: `lib/features/workspace/presentation/widgets/canvas/canvas_node_toolbar.dart`
- Modify: `lib/features/workspace/presentation/widgets/workspace_canvas.dart`

- [ ] **Step 1: Fix CanvasNodeToolbar colors**
Standardize the floating toolbar colors. Ensure they use `AppColors.elevatedSurface` or a slightly transparent `sidebarBackground` that works in both modes. Remove any potential light-mode gradients that bleed into dark mode.

- [ ] **Step 2: Refine _buildUnifiedToolbar**
Ensure the bottom canvas toolbar matches the side toolbar's styling precisely.

- [ ] **Step 3: Audit BackdropFilter usage**
Verify that `BackdropFilter` isn't catching a light layer from behind the island. Add a solid background color to the toolbar container to ensure opacity in dark mode.

---

### Task 4: Standardize Projects & Settings Pages

**Files:**
- Modify: `lib/features/projects/presentation/pages/projects_page.dart`
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`

- [ ] **Step 1: Refactor ProjectsPage to use PilotPanel**
Replace the hardcoded `Container` with `PilotPanel`.

- [ ] **Step 2: Add Island layout to SettingsPage**
Wrap `SettingsTable` in a `PilotPanel` with appropriate padding to match the "Islands" pattern. Ensure the page background is `AppColors.baseBackground`.

---

### Task 5: Global Color & Typography Audit

- [ ] **Step 1: Audit text colors**
Scan for `Colors.black` or `Colors.white` in UI components and replace them with `AppColors.textPrimary` or `AppColors.textSecondary`.

- [ ] **Step 2: Verify Status and Nav Bars**
Ensure `AppNavBar` (top) and `AppStatusBar` (bottom) have consistent or complementary colors that don't clash with the sidebars. Use `AppColors.baseBackground` for docked bars and `AppColors.sidebarBackground` for sidebars.

---

### Task 6: Final Validation

- [ ] **Step 1: Run flutter analyze**
`flutter analyze lib/`

- [ ] **Step 2: Visual check (manual)**
Verify light and dark mode consistency across all 5 major pages.
