# Global UI Performance Optimization Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate lag and stutter across the entire application by systematically resolving expensive rebuilds, inefficient state tracking, and missing render boundaries.

**Architecture:** 
1.  **Tab Virtualization:** Use `IndexedStack` in `WorkspacePage` to prevent destroying and recreating heavy editors/canvas instances on tab switch.
2.  **Surgical State Updates:** Replace top-level `setState` calls during high-frequency events (dragging, timers) with `ValueNotifier` and localized `ValueListenableBuilder` widgets.
3.  **Render Isolation:** Implement `RepaintBoundary` around static, complex, or independently animating components (e.g., list items, canvas nodes) to minimize GPU draw calls.
4.  **Provider Optimization:** Replace broad `context.watch` with targeted `context.select` or `Consumer` where appropriate to prevent cascading rebuilds.

**Tech Stack:** 
- Flutter
- Provider (`context.select`, `ChangeNotifier`)
- `ValueNotifier` / `ValueListenableBuilder`
- `RepaintBoundary` / `IndexedStack`

---

### Task 1: Instant Tab Switching in Workspace

**Files:**
- Modify: `lib/features/projects/presentation/pages/workspace_page.dart`

- [ ] **Step 1: Replace _buildTabContent with IndexedStack logic**

```dart
// Locate _buildTabContent usage in WorkspacePage build method.
// Change Expanded(child: _buildTabContent(activeTab)) to:

Expanded(
  child: Consumer<WorkspaceTabProvider>(
    builder: (context, tabProvider, _) {
      final tabs = tabProvider.tabs;
      final activeTabIndex = tabProvider.activeTabIndex;

      if (tabs.isEmpty) {
        return const _EmptyTabState();
      }

      return IndexedStack(
        index: activeTabIndex == -1 ? 0 : activeTabIndex,
        children: tabs.map((tab) {
          switch (tab.type) {
            case WorkspaceTabType.flow:
              return WorkspaceCanvas(selectedFlow: tab.data as flow_domain.Flow);
            case WorkspaceTabType.endpoint:
              return EndpointEditor(endpoint: tab.data as Endpoint);
            default:
              return const SizedBox.shrink();
          }
        }).toList(),
      );
    },
  ),
)
```

- [ ] **Step 2: Commit**
```bash
git add lib/features/projects/presentation/pages/workspace_page.dart
git commit -m "perf: implement instant tab switching using IndexedStack"
```

---

### Task 2: Fix EndpointEditor Interaction Lag

**Files:**
- Modify: `lib/features/shared/presentation/widgets/endpoint_editor.dart`
- Modify: `lib/features/endpoints/presentation/widgets/editor/endpoint_editor_response_panel.dart`

- [ ] **Step 1: Move execution timer to a dedicated ValueNotifier**

Replace `int _elapsedMs = 0;` with `final ValueNotifier<int> _elapsedMs = ValueNotifier(0);`.
Update the timer logic to `_elapsedMs.value += 10;` and remove `setState`.

- [ ] **Step 2: Update EndpointEditorResponsePanel to accept the notifier**

Change `final int elapsedMs;` to `final ValueNotifier<int> elapsedMsNotifier;`.
Wrap the Text widget displaying time in a `ValueListenableBuilder`:

```dart
if (isExecuting)
  ValueListenableBuilder<int>(
    valueListenable: elapsedMsNotifier,
    builder: (context, ms, _) {
      return Text('$ms ms', style: AppTypography.codeSm.copyWith(color: secondaryText));
    },
  )
```

- [ ] **Step 3: Commit**
```bash
git add lib/features/shared/presentation/widgets/endpoint_editor.dart lib/features/endpoints/presentation/widgets/editor/endpoint_editor_response_panel.dart
git commit -m "perf: isolate execution timer to prevent massive editor rebuilds"
```

---

### Task 3: Optimize Sidebar Dragging & Bottom Panel

**Files:**
- Modify: `lib/features/projects/presentation/pages/workspace_page.dart`
- Modify: `lib/features/shared/presentation/widgets/bottom_panel_shell.dart`

- [ ] **Step 1: Isolate Workspace Sidebar Dragging**

Convert `double _sidebarWidth = 260;` to `final ValueNotifier<double> _sidebarWidth = ValueNotifier(260.0);` in `WorkspacePage`.
Wrap `WorkspaceSidebar` and the Drag Handle in a `ValueListenableBuilder`. Update `onHorizontalDragUpdate` to modify `_sidebarWidth.value` without calling `setState`.

- [ ] **Step 2: Isolate Bottom Panel Shell Dragging**

In `bottom_panel_shell.dart`, ensure `onVerticalDragUpdate` modifies a local `ValueNotifier` for height instead of calling `setState` on the whole shell.

- [ ] **Step 3: Commit**
```bash
git add lib/features/projects/presentation/pages/workspace_page.dart lib/features/shared/presentation/widgets/bottom_panel_shell.dart
git commit -m "perf: use ValueNotifier for sidebar and panel resizing to achieve 60fps"
```

---

### Task 4: Canvas and List Render Optimization

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace/workspace_canvas.dart`
- Modify: `lib/features/projects/presentation/widgets/project/project_table.dart`

- [ ] **Step 1: Add RepaintBoundary to ProjectTableRow**

Wrap the row elements in `ProjectTable` with a `RepaintBoundary` to prevent list scrolling from repainting complex contents.

- [ ] **Step 2: Add RepaintBoundary to Canvas Nodes**

In `workspace_canvas.dart`, locate `Positioned` nodes within the Stack and wrap their children (`CanvasNodeBody`) in a `RepaintBoundary`.

- [ ] **Step 3: Run final analysis**

Run: `flutter analyze lib/`
Expected: No issues found!

- [ ] **Step 4: Commit**
```bash
git add .
git commit -m "perf: implement RepaintBoundaries for heavy UI components"
```
