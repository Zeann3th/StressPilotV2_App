# Projects Page White Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Projects page into a clean, pure white dashboard that matches the refined Fleet Light workspace aesthetic.

**Architecture:** 
1.  Refine `AppColorsLight` to use `#FFFFFF` for the `baseBackground`.
2.  Update `ProjectsPage` main container to use `AppColors.baseBackground` to ensure a consistent white surface.
3.  Refine the `_fleetLightTheme` definition in `ThemeManager` to reflect these changes.

**Tech Stack:** 
- Flutter
- Provider (ThemeManager)

---

### Task 1: Refine Light Theme Palette for Pure Whites

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`
- Modify: `lib/core/themes/theme_manager.dart`

- [ ] **Step 1: Update AppColorsLight constants in theme_tokens.dart**

```dart
abstract class AppColorsLight {
  static const baseBackground    = Color(0xFFFFFFFF); // PURE WHITE
  static const sidebarBackground = Color(0xFFF7F8FA); // COOL LIGHT GREY (for sidebars)
  static const elevatedSurface   = Color(0xFFFFFFFF); // PURE WHITE
  // ... rest same
}
```

- [ ] **Step 2: Update hardcoded _fleetLightTheme in theme_manager.dart**

```dart
  static final _fleetLightTheme = PilotTheme(
    id: 'fleet-light',
    name: 'JetBrains Fleet Light',
    brightness: Brightness.light,
    colors: {
      'background': const Color(0xFFFFFFFF), // PURE WHITE
      'surface': const Color(0xFFF7F8FA),    // SIDEBAR GREY
      'elevated': const Color(0xFFFFFFFF),   // WHITE
      // ... rest same
    },
  );
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/themes/theme_tokens.dart lib/core/themes/theme_manager.dart
git commit -m "style: refine Light Theme for pure white surfaces"
```

---

### Task 2: Refactor Projects Page for Sync

**Files:**
- Modify: `lib/features/projects/presentation/pages/projects_page.dart`

- [ ] **Step 1: Change main container color to baseBackground**

```dart
// lib/features/projects/presentation/pages/projects_page.dart

// L189
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.baseBackground, // USE WHITE BASE
                borderRadius: AppRadius.br16,
                border: Border.all(color: border),
              ),
```

- [ ] **Step 2: Update footer panels to use clean surface color**

```dart
// L240 & L247
                          Expanded(
                            child: _PanelContainer(
                              child: const RunsListWidget(flowId: null),
                            ),
                          ),
```
(Verify `_PanelContainer` uses `AppColors.baseBackground` or similar clean color).

- [ ] **Step 3: Commit**

```bash
git add lib/features/projects/presentation/pages/projects_page.dart
git commit -m "style: update ProjectsPage to use pure white theme"
```
