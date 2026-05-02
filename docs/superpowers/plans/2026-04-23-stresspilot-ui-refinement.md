# StressPilot UI Refinement & Feature Restoration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the UI to match JetBrains Fleet more closely, restore missing core features (endpoint upload, recent runs), and reorganize the workspace shell for better usability and aesthetics.

**Architecture:** 
- Unified `WorkspaceNavBar` containing project navigation, global actions (Marketplace, Runs, Settings), and workspace-specific controls (Play, Environment).
- New `StatusBar` for app-wide info and "Agent" bottom-panel toggle.
- Bottom-docked terminal-like panel for "Agent" interactions.
- Feature-first restoration of missing components from `main` branch.

**Tech Stack:** Flutter, Provider, Google Fonts (Inter), Lucide Icons, Shadcn UI.

---

### Task 1: UI Token & Typography Refinement

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`

- [ ] **Step 1: Update Typography to Inter**
Replace Montserrat with Inter for all UI text. Adjust weights and sizes to match Fleet density.

- [ ] **Step 2: Refine Colors and Radii**
Update `AppRadius.br6` and `AppRadius.br8` to ensure consistent rounded corners. Adjust `AppColors.border` and `AppColors.divider` for better visibility.

```dart
// lib/core/themes/theme_tokens.dart changes
static TextStyle get caption => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
static TextStyle get body    => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
static TextStyle get bodyMd  => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
static TextStyle get bodyLg  => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
static TextStyle get heading => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
static TextStyle get title   => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
```

- [ ] **Step 3: Commit**
```bash
git add lib/core/themes/theme_tokens.dart
git commit -m "style: switch UI font to Inter and refine theme tokens"
```

---

### Task 2: Restore Endpoint Upload Button

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

- [ ] **Step 1: Add upload action to _SidebarSection**
Implement `_handleUpload` in `_SidebarSectionState` similar to the logic in `workspace_endpoints_list.dart`.

- [ ] **Step 2: Add upload icon to _SectionHeader**
Update `_SectionHeader` to accept an optional `onUpload` callback and render an upload icon for the Endpoints section.

```dart
// Add to _SectionHeader
if (onUpload != null) 
  _IconButton(icon: LucideIcons.upload, onTap: onUpload),
```

- [ ] **Step 3: Commit**
```bash
git add lib/features/projects/presentation/widgets/workspace_sidebar.dart
git commit -m "feat: restore endpoint upload button in sidebar"
```

---

### Task 3: Restore Recent Runs Feature

**Files:**
- Create: `lib/features/results/presentation/pages/recent_runs_page.dart`
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`

- [ ] **Step 1: Create RecentRunsPage**
Use the `RunsListWidget` logic from `main` to create a page that shows all recent runs.

- [ ] **Step 2: Add Route**
Register `recentRunsRoute` in `AppRouter`.

- [ ] **Step 3: Add button to NavBar**
Add a button for "Recent Runs" (History icon) next to the Marketplace button in `WorkspaceNavBar`.

- [ ] **Step 4: Commit**
```bash
git add lib/features/results/presentation/pages/recent_runs_page.dart lib/core/navigation/app_router.dart lib/features/projects/presentation/widgets/workspace_nav_bar.dart
git commit -m "feat: restore recent runs page and add navigation button"
```

---

### Task 4: Workspace Shell Reorganization (Top Bar)

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`

- [ ] **Step 1: Move Project Picker to Center**
Wrap `_ProjectNameButton` in a `Center` or use `MainAxisAlignment` to position it in the middle of the `Row`.

- [ ] **Step 2: Move Play and Environment buttons to NavBar Right**
Port `_PlayStopButton` and `_EnvIconButton` from `project_workspace_page.dart` to `workspace_nav_bar.dart`.

- [ ] **Step 3: Remove _ActionBar**
Remove the `_ActionBar` widget and its usage from `ProjectWorkspacePage`.

- [ ] **Step 4: Commit**
```bash
git add lib/features/projects/presentation/widgets/workspace_nav_bar.dart lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "refactor: reorganize workspace top bar and remove action bar"
```

---

### Task 5: Bottom Panel & Agent Integration

**Files:**
- Create: `lib/features/shared/presentation/widgets/bottom_panel_shell.dart`
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Create: `lib/features/shared/presentation/widgets/status_bar.dart`

- [ ] **Step 1: Implement BottomPanelShell**
A widget that manages the visibility and height of a bottom panel (like a terminal).

- [ ] **Step 2: Create StatusBar**
A thin bar at the bottom of the screen containing project info on the left and "Agent" toggle on the right.

- [ ] **Step 3: Integrate into ProjectWorkspacePage**
Replace the simple `Scaffold` body with a layout that includes the `BottomPanelShell` and `StatusBar`.

- [ ] **Step 4: Move Agent to Panel**
Wrap `AgentPage` content in the bottom panel instead of navigating to a new page.

- [ ] **Step 5: Commit**
```bash
git add lib/features/shared/presentation/widgets/bottom_panel_shell.dart lib/features/shared/presentation/widgets/status_bar.dart lib/features/projects/presentation/pages/project_workspace_page.dart
git commit -m "feat: add bottom panel for agent and status bar"
```

---

### Task 6: Visual Polish Pass

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`
- Modify: `lib/core/themes/theme_tokens.dart`

- [ ] **Step 1: Polish Tabs**
Adjust padding, active border, and hover states of `WorkspaceTabBar` to match the Fleet screenshot.

- [ ] **Step 2: Workspace Layout Padding**
Add consistent margins (e.g., 8px) around the main content area and sidebar for a "floating panel" look.

- [ ] **Step 3: Commit**
```bash
git add lib/features/projects/presentation/widgets/workspace_tab_bar.dart lib/features/projects/presentation/widgets/workspace_sidebar.dart lib/core/themes/theme_tokens.dart
git commit -m "style: final visual polish pass for Fleet look"
```
