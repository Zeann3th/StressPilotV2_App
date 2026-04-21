# StressPilot UI Overhaul Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-skin the StressPilot app to match JetBrains Fleet's visual language, consolidating routes and updating the launch flow.

**Architecture:** Token-based theme migration. All visual values are centralized in `theme_tokens.dart`. Functional logic remains untouched. Workspace is updated to a sidebar-based layout with tabs.

**Tech Stack:** Flutter, Provider, Google Fonts, Lucide Icons, Shadcn UI.

---

### Task 1: Design Tokens & Theme Foundation

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`
- Modify: `lib/core/themes/theme_manager.dart`

- [ ] **Step 1: Update `theme_tokens.dart` with Fleet tokens**
  - Replace existing colors with Fleet values (Base: #1e1f22, Sidebar: #23242a, etc.)
  - Set typography to system sans-serif for UI and JetBrains Mono for code.
  - Define spacing and density constants (32px rows, 36px tabs, 40px nav).
  - Define radius constants (4px/6px).

- [ ] **Step 2: Update `ThemeManager` to prioritize Fleet theme**
  - Set Fleet as the default theme.
  - Ensure `ShadThemeData` generation uses the new tokens.

---

### Task 3: App Launch Flow

**Files:**
- Modify: `lib/core/app_root.dart`
- Modify: `lib/core/navigation/app_router.dart`

- [ ] **Step 1: Implement launch logic**
  - Check `SharedPreferences` for `last_project_id`.
  - If exists, navigate to `/workspace`.
  - Else, navigate to `/` (ProjectsPage / Recent Activity).

---

### Task 4: Workspace Shell & Sidebar

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Create: `lib/features/projects/presentation/widgets/workspace_sidebar.dart`
- Create: `lib/features/projects/presentation/widgets/workspace_nav_bar.dart`
- Create: `lib/features/projects/presentation/widgets/workspace_tab_bar.dart`

- [ ] **Step 1: Implement 40px Top Navigation Bar**
  - Left: Project name.
  - Right: Marketplace, Settings, Agent buttons.

- [ ] **Step 2: Implement Left Sidebar**
  - Fleet-style file tree for Endpoints and Flows.
  - Collapsible groups, uppercase labels.
  - Method badges (GET, POST, etc.) using tokens.

- [ ] **Step 3: Implement 36px Tab Bar**
  - Active tab with accent border-bottom.
  - Close button on hover.

---

### Task 5: Endpoint Management Consolidation

**Files:**
- Modify: `lib/features/projects/presentation/pages/project_workspace_page.dart`
- Modify: `lib/core/navigation/app_router.dart`
- Delete: `lib/features/endpoints/presentation/pages/endpoints_page.dart` (once consolidated)

- [ ] **Step 1: Integrate Endpoint editing into Workspace Tabs**
  - Selecting an endpoint in the sidebar opens it in a new tab.
  - Use existing UI from `endpoints_page.dart` but re-skinned.

---

### Task 6: Global Re-skin Pass

**Files:**
- Modify: All files in `lib/features/*/presentation/pages/`
- Modify: All files in `lib/features/*/presentation/widgets/`

- [ ] **Step 1: Apply tokens to Recent Activity (ProjectsPage)**
- [ ] **Step 2: Apply tokens to SettingsPage**
- [ ] **Step 3: Apply tokens to MarketplacePage**
- [ ] **Step 4: Apply tokens to EnvironmentPage (Env Var management)**
- [ ] **Step 5: Apply tokens to all Dialogs and Sheets**

---

### Task 7: Cleanup & Smoke Test

- [ ] **Step 1: Remove dead code and obsolete routes**
- [ ] **Step 2: Verify all navigation paths**
- [ ] **Step 3: Confirm 1:1 functional parity with new visuals**

---

Plan complete. Awaiting confirmation.
