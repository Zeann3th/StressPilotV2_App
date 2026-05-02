# Projects Page Layout Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the Projects page to mirror the Workspace page layout, featuring a redesigned sidebar with lifecycle actions, a "Search Anywhere" top bar, and a simplified recent activity dashboard.

**Architecture:** Refactor `ProjectsSidebar` to remove search and add Import/Export/New actions. Update `ProjectsPage` to use `GlobalSearchDropdown` in the top bar and simplify the main content area to show 5 recent activities.

**Tech Stack:** Flutter, Provider, Lucide Icons, StressPilot UI Components.

---

### Task 1: Refactor `ProjectsSidebar`

**Files:**
- Modify: `lib/features/projects/presentation/widgets/projects_sidebar.dart`

- [ ] **Step 1: Remove the search bar from `ProjectsSidebar`**

Remove the `Container` containing the `TextField` and its associated `TextEditingController` and `_searchQuery` state.

- [ ] **Step 2: Update `_ProjectsList` header to include Import, Export, and New Project buttons**

Update the `SidebarSectionHeader` trailing widget to include icon-only buttons for Import, Export, and New Project.

```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    _SidebarIconButton(
      icon: LucideIcons.upload,
      tooltip: 'Import Project',
      onTap: () => provider.importProject(),
    ),
    const SizedBox(width: 4),
    _SidebarIconButton(
      icon: LucideIcons.download,
      tooltip: 'Export Selected Project',
      onTap: provider.selectedProject == null 
          ? null 
          : () => provider.exportProject(provider.selectedProject!.id, provider.selectedProject!.name),
    ),
    const SizedBox(width: 4),
    _SidebarIconButton(
      icon: LucideIcons.plus,
      tooltip: 'New Project',
      onTap: () => _showCreateDialog(context),
    ),
  ],
),
```

- [ ] **Step 3: Ensure `_ProjectSidebarRow` handles `onDoubleTap` correctly**

Verify that `onDoubleTap` navigates to the Workspace page. (Already implemented, but double check consistency).

- [ ] **Step 4: Commit changes**

```bash
git add lib/features/projects/presentation/widgets/projects_sidebar.dart
git commit -m "refactor: update projects sidebar with lifecycle actions and remove search"
```

---

### Task 2: Refactor `ProjectsPage` Topbar

**Files:**
- Modify: `lib/features/projects/presentation/pages/projects_page.dart`

- [ ] **Step 1: Replace the search input with `GlobalSearchDropdown`**

Update the `AppNavBar` `center` parameter to use `GlobalSearchDropdown`.

```dart
AppNavBar(
  onToggleSidebar: _toggleSidebar,
  isSidebarOpen: _isSidebarOpen,
  center: const SizedBox(
    width: 400,
    child: GlobalSearchDropdown(),
  ),
),
```

- [ ] **Step 2: Commit changes**

```bash
git add lib/features/projects/presentation/pages/projects_page.dart
git commit -m "feat: integrate global search anywhere into projects page topbar"
```

---

### Task 3: Refactor `ProjectsPage` Main Content

**Files:**
- Modify: `lib/features/projects/presentation/pages/projects_page.dart`

- [ ] **Step 1: Simplify the main content area to show 5 recent activities**

Remove the "Recent Executions" section and the "Dashboard" header if it feels redundant. Use a layout that matches the "Select endpoint or flow" empty state of the Workspace page but populated with `RecentPagesWidget`.

```dart
// Inside ProjectsPage build method, main content area:
Expanded(
  child: Container(
    decoration: BoxDecoration(
      color: AppColors.baseBackground,
      borderRadius: AppRadius.br6,
      border: Border.all(color: border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        // Tab-like header for consistency
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.sidebarBackground,
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.history, size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'RECENT ACTIVITY',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: RecentPagesWidget(),
          ),
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 2: Verify `AppStatusBar` usage**

Ensure `AppStatusBar` is called with `projectName: null` (or let it watch the provider which will be null if no project is selected).

- [ ] **Step 3: Commit changes**

```bash
git add lib/features/projects/presentation/pages/projects_page.dart
git commit -m "ui: simplify projects page main content to show recent activity"
```

---

### Task 4: Validation

- [ ] **Step 1: Run Flutter analyzer**

Run: `flutter analyze lib/`
Expected: No errors related to modified files.

- [ ] **Step 2: Verify double-click behavior**

In the running app, double-click a project in the sidebar and verify it opens the Workspace page.

- [ ] **Step 3: Verify Tooltips**

Hover over the Import, Export, and Plus buttons in the sidebar and verify tooltips appear.

- [ ] **Step 4: Verify Search Anywhere**

Use the search bar in the topbar and verify it shows results across projects/flows/endpoints.
