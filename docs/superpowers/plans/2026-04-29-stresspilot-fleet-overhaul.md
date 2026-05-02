# StressPilot JetBrains Fleet UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-skin StressPilot to match JetBrains Fleet aesthetics, remove the Agent feature, and refactor the launch flow for instant non-blocking entry.

**Architecture:** 
- **Fleet Design System:** Implement a strict set of design tokens and apply them globally.
- **Integrated Workspace:** Consolidate endpoint and flow management into a single tabbed workspace with a persistent sidebar.
- **Non-blocking Startup:** Launch the backend in the background, allowing immediate UI interaction with skeletons and project-name persistence.
- **Icon-First UI:** Prioritize icons over text, using tooltips/hover for text labels.

**Tech Stack:** Flutter, Provider, Lucide Icons (or existing icon set), Shadcn UI, Shared Preferences.

---

### Task 1: Agent Feature Removal & Dependency Cleanup

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/system/process_manager.dart`
- Modify: `lib/core/di/locator.dart`
- Modify: `lib/core/app_root.dart`
- Modify: `lib/core/navigation/app_router.dart`
- Delete: `lib/features/agent/`
- Delete: `assets/agent/`

- [ ] **Step 1: Remove dependencies and assets from `pubspec.yaml`**
    - Remove `xterm` and `flutter_pty`.
    - Remove `assets/agent/` from the assets section.
- [ ] **Step 2: Remove agent logic from `ProcessManager`**
    - Delete `startAgent`, `stopAgent`, `resolveAgentPath`, `resolveAgentSourceDir`.
- [ ] **Step 3: Remove agent traces from DI and Navigation**
    - Remove `AgentProvider` registration in `locator.dart`.
    - Remove `agentRoute` and `AgentPage` from `app_router.dart`.
- [ ] **Step 4: Delete agent feature folder and assets**
    - `rm -rf lib/features/agent`
    - `rm -rf assets/agent`
- [ ] **Step 5: Run `flutter pub get` and verify analysis**
    - Run: `flutter pub get && flutter analyze lib/`
- [ ] **Step 6: Commit**
    - `git commit -m "chore: remove agent feature and cleanup dependencies"`

---

### Task 2: Fleet Design Tokens & Global Theme Pass

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`
- Modify: `lib/core/themes/pilot_theme.dart` (if exists) or equivalent.

- [ ] **Step 1: Define Fleet Colors and Typography in `theme_tokens.dart`**
    - Base background: `#1e1f22`
    - Sidebar: `#23242a`
    - Elevation: `#2b2c33`
    - Selected: `#383a47`
    - Hover: `#2e2f38`
    - Accent: `#7b68ee`
    - Method colors: GET `#57a64a`, POST `#4b8fd4`, PUT `#c8a84b`, DELETE `#c25151`, PATCH `#8b68d4`
- [ ] **Step 2: Apply Fleet tokens to Shadcn theme**
    - Update `ShadThemeData` in `pilot_theme.dart` or where defined.
- [ ] **Step 3: Commit**
    - `git commit -m "style: implement JetBrains Fleet design tokens"`

---

### Task 3: Non-blocking Launch Flow & Skeletons

**Files:**
- Modify: `lib/core/app_root.dart`
- Modify: `lib/core/system/process_manager.dart`
- Modify: `lib/features/shared/presentation/widgets/app_skeleton.dart` (if exists, else create)

- [ ] **Step 1: Refactor `AppRoot._init` for non-blocking startup**
    - Start `ProcessManager.startBackend` and `SessionManager.initializeSession` in parallel (unawaited).
    - Set `_initialized = true` immediately.
    - Determine `_initialRoute` by checking `ProjectProvider.hasSelectedProject` (which is already loaded in `initialize()`).
- [ ] **Step 2: Add "Indexing" status to `AppStateManager`**
    - Track backend health status to show the indexing indicator in the bottom bar.
- [ ] **Step 3: Update `AppSkeleton` to show project name from SharedPrefs**
    - Use the project name stored in `ProjectProvider.selectedProject?.name` even if the backend isn't up.
- [ ] **Step 4: Commit**
    - `git commit -m "feat: implement non-blocking app launch and indexing indicator"`

---

### Task 4: Integrated Workspace Shell (Sidebar & Nav Bar)

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`
- Modify: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`

- [ ] **Step 1: Implement Fleet-style Sidebar**
    - Integrated Endpoints and Flows lists.
    - Collapsible sections.
    - CRUD actions on hover.
- [ ] **Step 2: Update Workspace Nav Bar**
    - Move Marketplace and Settings to the top right.
    - Keep Project name dropdown in the middle.
    - Ensure icon-first buttons (show text only on hover).
- [ ] **Step 3: Commit**
    - `git commit -m "feat: integrated workspace shell with Fleet sidebar and nav bar"`

---

### Task 5: Tabbed Workspace & Response Panel Refinement

**Files:**
- Modify: `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`
- Modify: `lib/features/endpoints/presentation/widgets/endpoint_response_view.dart` (path approximate)
- Modify: `lib/features/shared/presentation/widgets/layout.dart` (bottom bar)

- [ ] **Step 1: Refine Workspace Tab Bar**
    - Match Fleet tab styles (inactive vs active).
    - Close button on hover.
- [ ] **Step 2: Update Response Panel Behavior**
    - Remove magnifying glass.
    - Add "-" button to collapse (hide) the response panel.
    - **Initial state:** Response tab is closed by default when navigating to an endpoint.
    - **Run Action:** Ensure the response panel automatically opens when an endpoint is run.
    - Add terminal icon to bottom bar (to the right of history) to toggle visibility.
- [ ] **Step 3: Fix Endpoint Upload Logic**
    - In the sidebar upload action, ensure `FilePicker` result is checked before calling the import API.
    - Verify against `ProjectProvider.importProject` or equivalent.
- [ ] **Step 4: Commit**
    - `git commit -m "feat: tabbed workspace and collapsible response panel with auto-open on run"`

---

### Task 6: Final Global Re-skin & Cleanup

**Files:**
- Modify: `lib/features/projects/presentation/pages/recent_activity_page.dart`
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`
- Modify: `lib/features/marketplace/presentation/pages/marketplace_page.dart`

- [ ] **Step 1: Re-skin Recent Activity Page**
- [ ] **Step 2: Re-skin Settings & Marketplace Pages**
- [ ] **Step 3: Final `flutter analyze` and smoke test**
- [ ] **Step 4: Commit**
    - `git commit -m "style: final global re-skin to match JetBrains Fleet"`

---

### Verification Strategy
- **Manual Verification:**
    - Launch app: check if it enters instantly.
    - Verify project name is shown immediately if a project was previously selected.
    - Check "Indexing" indicator vanishes once backend is up.
    - Verify sidebar CRUD actions and tab behavior.
    - Check response panel toggle.
- **Automated Verification:**
    - Run `flutter analyze lib/` after each task.
    - Run existing unit tests: `flutter test`.
