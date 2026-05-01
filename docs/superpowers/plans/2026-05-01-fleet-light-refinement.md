# Fleet Light Theme Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the refined "Actual Fleet Light" palette to the application and ensure it uses the same reactive logic as the dark theme.

**Architecture:** 
1.  Update `lib/core/themes/theme_tokens.dart` (`AppColorsLight`) with refined hex values.
2.  Update `lib/core/themes/theme_manager.dart` (`_fleetLightTheme`) to match.
3.  Ensure all dynamic getters in `AppColors` correctly fall back to these new light values when in light mode.

**Tech Stack:** 
- Flutter
- Provider (ThemeManager)

---

### Task 1: Update Light Theme Tokens

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`
- Modify: `lib/core/themes/theme_manager.dart`

- [ ] **Step 1: Update AppColorsLight constants in theme_tokens.dart**

```dart
abstract class AppColorsLight {
  static const baseBackground    = Color(0xFFF7F8FA);
  static const sidebarBackground = Color(0xFFFFFFFF);
  static const elevatedSurface   = Color(0xFFFFFFFF);
  static const activeItem        = Color(0xFFE4E6ED);
  static const hoverItem         = Color(0xFFF0F1F5);
  static const accent            = Color(0xFF3574F0);
  static const accentHover       = Color(0xFF4B85F2);
  static const border            = Color(0x1F000000);
  static const divider           = Color(0x14000000);
  static const textPrimary       = Color(0xFF19191C);
  static const textSecondary     = Color(0xFF70727A);
  static const textDisabled      = Color(0xFFAAAAAA);
  static const accentActive      = Color(0xFF2E68E0);

  static const methodGet    = Color(0xFF57A64A);
  static const methodPost   = Color(0xFF3574F0); // Match light accent
  static const methodPut    = Color(0xFFC8A84B);
  static const methodDelete = Color(0xFFC25151);
  static const methodPatch  = Color(0xFF8B68D4);
  static const error        = Color(0xFFD2504B);
  static const success      = methodGet;
  static const warning      = methodPut;
  static const info         = methodPost;
}
```

- [ ] **Step 2: Update hardcoded _fleetLightTheme in theme_manager.dart**

```dart
  static final _fleetLightTheme = PilotTheme(
    id: 'fleet-light',
    name: 'JetBrains Fleet Light',
    brightness: Brightness.light,
    colors: {
      'background': const Color(0xFFF7F8FA),
      'surface': const Color(0xFFFFFFFF),
      'elevated': const Color(0xFFFFFFFF),
      'activeItem': const Color(0xFFE4E6ED),
      'hoverItem': const Color(0xFFF0F1F5),
      'accent': const Color(0xFF3574F0),
      'textPrimary': const Color(0xFF19191C),
      'textSecondary': const Color(0xFF70727A),
      'textDisabled': const Color(0xFFAAAAAA),
    },
  );
```

- [ ] **Step 3: Verify dynamic fallback mapping**

Ensure `AppColors.baseBackground` and others correctly handle light mode fallbacks if theme keys are missing (they already do via the static definitions updated in Step 1).

- [ ] **Step 4: Commit**

```bash
git add lib/core/themes/theme_tokens.dart lib/core/themes/theme_manager.dart
git commit -m "style: refine Fleet Light theme tokens to match actual aesthetic"
```

---

### Task 2: Verification and Final Polish

- [ ] **Step 1: Run global analysis**

Run: `flutter analyze lib/`
Expected: PASS

- [ ] **Step 2: Test Theme Toggle**

Verify that toggling between Fleet Dark and Fleet Light results in an immediate, global refresh of all components with the new cooler color palettes.
