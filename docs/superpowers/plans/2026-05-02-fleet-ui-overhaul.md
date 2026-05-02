# JetBrains Fleet UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refine the UI to match the JetBrains Fleet "Islands" aesthetic, primarily by increasing corner radii and adjusting component styling for an "organic" feel.

**Architecture:**
1. Update `AppRadius` tokens to use larger, Fleet-spec values (12-16px for islands).
2. Enhance `AppShadows` to provide very subtle "floating" depth.
3. Update core layout containers (Sidebar, Main Content) to use the new "Island" radius.
4. Refine button and input styles to be more consistent with Fleet.

**Tech Stack:** Flutter, StressPilot Theme System.

---

### Task 1: Update Design Tokens

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`

- [ ] **Step 1: Increase `AppRadius` values**

Fleet uses larger radii for main panels to create that "organic" look.

```dart
abstract class AppRadius {
  static const r4  = Radius.circular(4);
  static const r6  = Radius.circular(6);
  static const r8  = Radius.circular(8);
  static const r10 = Radius.circular(10);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);

  static const br4  = BorderRadius.all(r4);
  static const br6  = BorderRadius.all(r6);
  static const br8  = BorderRadius.all(r8);
  static const br10 = BorderRadius.all(r10);
  static const br12 = BorderRadius.all(r12);
  static const br16 = BorderRadius.all(r16);
}
```

- [ ] **Step 2: Add subtle "Island" shadows**

Fleet panels often have a very soft, multi-layered shadow to feel "lifted."

```dart
abstract class AppShadows {
  static List<BoxShadow> get panel => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
```

- [ ] **Step 3: Commit**

---

### Task 2: Apply "Island" Styling to Main Layout

**Files:**
- Modify: `lib/features/workspace/presentation/pages/workspace_page.dart`
- Modify: `lib/features/projects/presentation/pages/projects_page.dart`

- [ ] **Step 1: Update Workspace Page Main Container**

Ensure the main content area uses `AppRadius.br12` or `br16` and apply the panel shadow if it's supposed to feel floating.

```dart
// Inside WorkspacePage build:
Expanded(
  child: Container(
    decoration: BoxDecoration(
      color: AppColors.baseBackground,
      borderRadius: AppRadius.br12, // Increased from br6
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.panel, // Added for "Island" feel
    ),
    // ...
```

- [ ] **Step 2: Update Projects Page Main Container**

```dart
// Inside ProjectsPage build:
Expanded(
  child: Container(
    decoration: BoxDecoration(
      color: AppColors.baseBackground,
      borderRadius: AppRadius.br12, // Increased from br6
      border: Border.all(color: border),
      boxShadow: AppShadows.panel, // Added for "Island" feel
    ),
    // ...
```

- [ ] **Step 3: Update Sidebars**

Sidebars in Fleet often have rounded tops/bottoms when they are part of an island. If they are docked, they might only have rounded corners on the "inside" edges. Let's apply consistent rounding.

---

### Task 3: Refine Input and Button Components

**Files:**
- Modify: `lib/core/themes/components/buttons/pilot_button.dart` (Assuming path)
- Modify: `lib/core/themes/components/inputs/pilot_input.dart` (Assuming path)

- [ ] **Step 1: Update `PilotButton` radius**

Use `AppRadius.br8` or `br10` for buttons to match Fleet's softer edges.

- [ ] **Step 2: Update `PilotInput` radius**

Use `AppRadius.br8` for inputs.

---

### Task 4: Validation

- [ ] **Step 1: Check Light/Dark visibility**
- [ ] **Step 2: Run static analysis**
