# UI Performance Optimization Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate lag and stutter in the UI by implementing high-performance state management, surgical rebuilds, and tab virtualization.

**Architecture:** 
1.  **Instant Tab Switching:** Use `IndexedStack` in `WorkspacePage` to keep all open tabs in memory and switch between them at 60 FPS.
2.  **Surgical Timer Updates:** Extract the execution timer in `EndpointEditor` into a dedicated `ValueNotifier` widget to prevent the entire editor from rebuilding every 10ms.
3.  **Sidebar Resize Isolation:** Use `ValueNotifier` for sidebar width to prevent the entire workspace from rebuilding during drag.
4.  **Repaint Boundaries:** Add `RepaintBoundary` to complex components (Canvas, JSON Viewer, List Items) to isolate GPU rendering.

**Tech Stack:** 
- Flutter
- ValueNotifier / ValueListenableBuilder
- RepaintBoundary

---

### Task 1: Instant Tab Switching in Workspace

**Files:**
- Modify: `lib/features/projects/presentation/pages/workspace_page.dart`

- [ ] **Step 1: Replace _buildTabContent with IndexedStack logic**

```dart
// Update build() to use IndexedStack for tabs
final tabs = context.watch<WorkspaceTabProvider>().tabs;
final activeTabIndex = context.watch<WorkspaceTabProvider>().activeTabIndex;

// ...
Expanded(
  child: IndexedStack(
    index: activeTabIndex == -1 ? 0 : activeTabIndex,
    children: tabs.isEmpty 
        ? [const _EmptyTabState()]
        : tabs.map((tab) => _buildTabContent(tab)).toList(),
  ),
)
```

- [ ] **Step 2: Commit**
```bash
git add lib/features/projects/presentation/pages/workspace_page.dart
git commit -m "perf: implement instant tab switching with IndexedStack"
```

---

### Task 2: Fix EndpointEditor Interaction Lag

**Files:**
- Modify: `lib/features/shared/presentation/widgets/endpoint_editor.dart`
- Modify: `lib/features/endpoints/presentation/widgets/editor/endpoint_editor_response_panel.dart`

- [ ] **Step 1: Move timer state to ValueNotifier**

- [ ] **Step 2: Create a dedicated _TimerDisplay widget that wraps only the Text**

- [ ] **Step 3: Remove setState from the 10ms periodic timer loop**

- [ ] **Step 4: Commit**
```bash
git add lib/features/shared/presentation/widgets/endpoint_editor.dart
git commit -m "perf: isolate execution timer to prevent full editor rebuilds"
```

---

### Task 3: Optimize Sidebar Resize and Search

**Files:**
- Modify: `lib/features/projects/presentation/pages/workspace_page.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`

- [ ] **Step 1: Use ValueNotifier for _sidebarWidth**

- [ ] **Step 2: Wrap Sidebar and Handle in ValueListenableBuilder**

- [ ] **Step 3: Add RepaintBoundary to WorkspaceSidebar and WorkspaceCanvas**

- [ ] **Step 4: Commit**
```bash
git add lib/features/projects/presentation/pages/workspace_page.dart
git commit -m "perf: optimize sidebar resize and add repaint boundaries"
```

---

### Task 4: List and Dropdown Rendering Fixes

**Files:**
- Modify: `lib/features/shared/presentation/widgets/global_search_dropdown.dart`
- Modify: `lib/features/projects/presentation/widgets/project/project_table.dart`

- [ ] **Step 1: Add RepaintBoundary to NavigationItem and ProjectTableRow**

- [ ] **Step 2: Commit**
```bash
git add lib/features/shared/presentation/widgets/global_search_dropdown.dart lib/features/projects/presentation/widgets/project/project_table.dart
git commit -m "perf: add repaint boundaries to list items for smoother scrolling"
```
