# UI Bug Fixes and Global Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the `ParentDataWidget` layout error in the AppNavBar, implement various UI fixes (tab overflow, settings status bar, endpoint configuration styling and logic), and apply the global "Islands" UI refinement.

**Architecture:** We will revert the `AppNavBar` flex layout back to a `Stack` to support `Positioned` widgets. We will update the `EndpointEditorTabs` and execution logic to handle `variables` correctly. We will modify `WorkspaceTabBar` to support scrolling or a dropdown for overflow. Finally, we will implement the global UI refinements defined in the original May 4th plan.

**Tech Stack:** Flutter, Provider, Theme Tokens

---

### Task 1: Fix AppNavBar Layout (ParentDataWidget Error)

**Files:**
- Modify: `lib/features/shared/presentation/widgets/layout/app_nav_bar.dart`

- [ ] **Step 1: Revert Row to Stack in AppNavBar**
The `Incorrect use of ParentDataWidget` error is caused by using `Positioned` directly inside a `Row`. Revert the `Row` back to a `Stack` in the `build` method of `AppNavBar` to restore the original layout (sidebar toggle on left, center widget, controls on right).

```dart
// Replace this:
      child: Row(
        children: [
          Positioned.fill(child: MoveWindow()),

// With this:
      child: Stack(
        children: [
          Positioned.fill(child: MoveWindow()),
```

- [ ] **Step 2: Verify AppNavBar Layout**
Ensure the `Positioned` widgets for left, center, and right sections have appropriate constraints and positions within the `Stack`.

---

### Task 2: Fix Settings Page Status Bar

**Files:**
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`

- [ ] **Step 1: Remove AppStatusBar from SettingsPage**
Remove the `AppStatusBar` widget from the bottom of the `Column` in `SettingsPage`. The settings page does not need a status bar.

```dart
// Remove this line from the Column children:
// const AppStatusBar(projectName: null),
```

---

### Task 3: Update Endpoint Configuration Tab (Run Variables)

**Files:**
- Modify: `lib/features/endpoints/presentation/widgets/editor/endpoint_editor_tabs.dart`
- Modify: `lib/features/shared/presentation/widgets/endpoint_editor.dart`

- [ ] **Step 1: Rename "Result Variables" to "Run Variables"**
In `EndpointEditorTabs._buildConfigurationTab`, change the section title from "Result Variables" to "Run Variables".

- [ ] **Step 2: Update Run Variables Styling**
Remove the boxed container styling around the `KeyValueEditor` for variables so it matches the look of the Params and Headers tabs.

```dart
// Change from:
        Container(
          constraints: const BoxConstraints(minHeight: 160, maxHeight: 400),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: AppRadius.br8,
            color: AppColors.sidebarBackground,
          ),
          child: KeyValueEditor(
            data: variables,
            onChanged: onVariablesChanged,
            controller: settingsScrollCtrl,
          ),
        ),

// To:
        SizedBox(
          height: 300, // Or appropriate constraint
          child: KeyValueEditor(
            data: variables,
            onChanged: onVariablesChanged,
            controller: settingsScrollCtrl,
          ),
        ),
```

- [ ] **Step 3: Ensure variables are sent in JSON request**
In `EndpointEditor._syncToProvider`, ensure the `variables` state is included in the transient data if it wasn't already. And in `EndpointEditor._save`, make sure `variables` is included in the data sent to the backend. Also, ensure the execution payload in `_PlayStopButton` handles variables correctly if necessary. (Check how params and headers are saved and executed).

---

### Task 4: Handle Tab Overflow in WorkspaceTabBar

**Files:**
- Modify: `lib/features/workspace/presentation/widgets/workspace_tab_bar.dart`

- [ ] **Step 1: Add Dropdown Menu for Tab Overflow**
If there are many tabs, the `ReorderableListView` might need a way to show hidden tabs. Alternatively, wrap the `ReorderableListView` in a layout that includes a trailing dropdown icon button (`LucideIcons.chevronDown`) when the list overflows, or simply ensure the horizontal list scrolls nicely with a visible scrollbar. If a dropdown is preferred, implement a `PopupMenuButton` at the end of the tab bar row that lists all open tabs and allows selecting one.

---

### Task 5: Enhance PilotPanel for Global Use

**Files:**
- Modify: `lib/core/themes/components/layout/pilot_panel.dart`

- [ ] **Step 1: Add flexible styling options to PilotPanel**
Update `PilotPanel` to support different background colors, border visibility, and shadow configurations.

```dart
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

---

### Task 6: Standardize Workspace Page & Tab Bar

**Files:**
- Modify: `lib/features/workspace/presentation/pages/workspace_page.dart`
- Modify: `lib/features/workspace/presentation/widgets/workspace_tab_bar.dart`

- [ ] **Step 1: Use PilotPanel for Workspace main island**
Ensure the main content area in `WorkspacePage` uses the enhanced `PilotPanel`.

- [ ] **Step 2: Unify WorkspaceTabBar background**
Change `WorkspaceTabBar` background from `AppColors.sidebarBackground` to `Colors.transparent` so it inherits the island's background.

---

### Task 7: Fix Canvas Toolbars & Dark Mode Error

**Files:**
- Modify: `lib/features/workspace/presentation/widgets/canvas/canvas_node_toolbar.dart`
- Modify: `lib/features/workspace/presentation/widgets/workspace_canvas.dart`

- [ ] **Step 1: Fix CanvasNodeToolbar colors**
Standardize the floating toolbar colors to use `AppColors.elevatedSurface`.

- [ ] **Step 2: Audit BackdropFilter usage**
Verify that `BackdropFilter` isn't catching a light layer from behind the island. Add a solid background color to the toolbar container to ensure opacity in dark mode.

---

### Task 8: Standardize Projects & Settings Pages

**Files:**
- Modify: `lib/features/projects/presentation/pages/projects_page.dart`
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`

- [ ] **Step 1: Refactor ProjectsPage to use PilotPanel**
Replace the hardcoded `Container` with `PilotPanel`.

- [ ] **Step 2: Add Island layout to SettingsPage**
Wrap `SettingsTable` in a `PilotPanel` with appropriate padding.

---

### Task 9: Final Validation

- [ ] **Step 1: Run flutter analyze**
`dart analyze lib/`

- [ ] **Step 2: Run Tests**
`flutter test`

- [ ] **Step 3: Commit**
`git add . && git commit -m "fix: ui bugs and apply global refinement"`
