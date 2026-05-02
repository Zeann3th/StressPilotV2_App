# Fleet Theme Refinement & Reactivity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the app to the "Actual Fleet" color palette and ensure 100% instant theme reactivity across all widgets.

**Architecture:** 
1.  Update `lib/core/themes/theme_tokens.dart` and `ThemeManager` with the user's specific hex palette.
2.  Perform a regex-based scan for "color caching" anti-patterns (e.g., colors stored in `initState`).
3.  Refactor identified widgets to use the dynamic `AppColors` getters directly in their `build` methods.

**Tech Stack:** 
- Flutter
- Provider (ThemeManager)

---

### Task 1: Update Fleet Theme Tokens

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`
- Modify: `lib/core/themes/theme_manager.dart`

- [ ] **Step 1: Update AppColors fallback values in theme_tokens.dart**

```dart
abstract class AppColors {
  // NEW Fleet Actual Palette
  static const _fallbackBackground = Color(0xFF1E1F28); // Was 1E1F22
  static const _fallbackSidebar    = Color(0xFF22232D); // Was 23242A
  static const _fallbackElevated   = Color(0xFF2A2B36); // Was 2B2C33
  static const _fallbackActive     = Color(0xFF2E3044); // Was 383A47
  static const _fallbackHover      = Color(0xFF272838); // Was 2E2F38
  static const _fallbackAccent     = Color(0xFF5B9BD5); // Was 7B68EE
  static const _fallbackText       = Color(0xFFD4D4D6); // Was DCD9D0
  static const _fallbackSecondary  = Color(0xFF757580); // Was 7E7C75
  static const _fallbackDisabled   = Color(0xFF45454E); // Was 4A4845
  
  // ... (getters remain same as they already use these fallbacks)
}
```

- [ ] **Step 2: Update hardcoded _fleetTheme in theme_manager.dart**

```dart
  static final _fleetTheme = PilotTheme(
    id: 'fleet',
    name: 'JetBrains Fleet',
    brightness: Brightness.dark,
    colors: {
      'background': const Color(0xFF1E1F28),
      'surface': const Color(0xFF22232D),
      'elevated': const Color(0xFF2A2B36),
      'activeItem': const Color(0xFF2E3044),
      'hoverItem': const Color(0xFF272838),
      'accent': const Color(0xFF5B9BD5),
      'textPrimary': const Color(0xFFD4D4D6),
      'textSecondary': const Color(0xFF757580),
      'textDisabled': const Color(0xFF45454E),
    },
  );
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/themes/theme_tokens.dart lib/core/themes/theme_manager.dart
git commit -m "style: update Fleet tokens to actual hex palette"
```

---

### Task 2: Reactivity Scan and Color Caching Audit

**Goal:** Identify and fix widgets that "capture" colors once instead of re-reading them.

- [ ] **Step 1: Scan for colors in initState**

Run: `grep_search pattern: "initState.*AppColors"`
Expected: Identify widgets that set color variables in `initState`.

- [ ] **Step 2: Scan for color instance variables**

Run: `grep_search pattern: "final Color .* = AppColors"`
Expected: Identify widgets that cache colors at the class level.

- [ ] **Step 3: Refactor found instances**

Example refactor:
```dart
// FROM:
class _MyWidgetState extends State {
  late Color _color;
  void initState() { _color = AppColors.background; }
  Widget build() { return Container(color: _color); }
}

// TO:
class _MyWidgetState extends State {
  Widget build() { return Container(color: AppColors.background); }
}
```

- [ ] **Step 4: Commit all reactivity fixes**

```bash
git add .
git commit -m "refactor: ensure 100% theme reactivity by removing color caching"
```
