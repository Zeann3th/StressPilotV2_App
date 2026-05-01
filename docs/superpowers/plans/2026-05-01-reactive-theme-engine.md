# Reactive Theme Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable instant, global UI theme switching by refactoring `AppColors` to use dynamic getters linked to the `ThemeManager`.

**Architecture:** 
1.  Refactor `AppColors` to use `getIt<ThemeManager>().currentTheme.getColor()` for all properties instead of static constants.
2.  Update `AppTypography` to use dynamic `AppColors` getters.
3.  Ensure `AppRoot`'s `_AppTheme` widget correctly watches `ThemeManager` and rebuilds the entire `ShadApp` with a unique `ValueKey`.

**Tech Stack:** 
- Flutter
- Provider (ChangeNotifier)
- GetIt (Service Locator)
- Shadcn UI (Flutter)

---

### Task 1: Refactor AppColors to Dynamic Getters

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart`

- [ ] **Step 1: Update AppColors to use dynamic getters linked to ThemeManager**

```dart
abstract class AppColors {
  // Base Colors (Fallbacks for when theme keys are missing)
  static const _fallbackBackground = Color(0xFF1E1F22);
  static const _fallbackSidebar    = Color(0xFF23242A);
  static const _fallbackElevated   = Color(0xFF2B2C33);
  static const _fallbackActive     = Color(0xFF383A47);
  static const _fallbackHover      = Color(0xFF2E2F38);
  static const _fallbackAccent     = Color(0xFF7B68EE);
  static const _fallbackText       = Color(0xFFDCD9D0);
  static const _fallbackSecondary  = Color(0xFF7E7C75);
  static const _fallbackDisabled   = Color(0xFF4A4845);

  // Private helper to get current theme
  static PilotTheme get _theme => getIt<ThemeManager>().currentTheme;

  // Dynamic Getters
  static Color get baseBackground    => _theme.getColor('background',    _fallbackBackground);
  static Color get sidebarBackground => _theme.getColor('surface',       _fallbackSidebar);
  static Color get elevatedSurface   => _theme.getColor('elevated',      _fallbackElevated);
  static Color get activeItem        => _theme.getColor('activeItem',    _fallbackActive);
  static Color get hoverItem         => _theme.getColor('hoverItem',     _fallbackHover);
  static Color get accent            => _theme.getColor('accent',        _fallbackAccent);
  static Color get accentHover       => _theme.getColor('accentHover',   accent.withValues(alpha: 0.85));
  static Color get accentActive      => _theme.getColor('accentActive',  accent.withValues(alpha: 0.7));

  static Color get border            => _theme.getColor('border',        const Color(0x14FFFFFF));
  static Color get divider           => _theme.getColor('divider',       const Color(0x0FFFFFFF));

  static Color get textPrimary       => _theme.getColor('textPrimary',   _fallbackText);
  static Color get textSecondary     => _theme.getColor('textSecondary', _fallbackSecondary);
  static Color get textDisabled      => _theme.getColor('textDisabled',  _fallbackDisabled);
  static Color get textMuted         => textDisabled;

  static Color get methodGet         => _theme.getColor('success',       const Color(0xFF57A64A));
  static Color get methodPost        => _theme.getColor('info',          const Color(0xFF4B8FD4));
  static Color get methodPut         => _theme.getColor('warning',       const Color(0xFFC8A84B));
  static Color get methodDelete      => _theme.getColor('methodDelete',  const Color(0xFFC25151));
  static Color get methodPatch       => _theme.getColor('methodPatch',   const Color(0xFF8B68D4));

  static Color get error             => _theme.getColor('error',         const Color(0xFFD2504B));
  static Color get success           => methodGet;
  static Color get warning           => methodPut;
  static Color get info              => methodPost;

  // Legacy mappings for backward compatibility
  static Color get background => baseBackground;
  static Color get surface    => sidebarBackground;
  static Color get elevated   => elevatedSurface;
  static Color get borderCol  => border;
  static Color get primary    => textPrimary;
  static Color get secondary  => textSecondary;
  static Color get muted      => textDisabled;
  static Color get accentColor => accent;
}
```

- [ ] **Step 2: Update AppGradients to be dynamic**

```dart
abstract class AppGradients {
  static LinearGradient green([bool? isDark]) {
    final color = AppColors.accent;
    return LinearGradient(
      colors: [color, color.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
```

- [ ] **Step 3: Verify no syntax errors in theme_tokens.dart**

Run: `flutter analyze lib/core/themes/theme_tokens.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/core/themes/theme_tokens.dart
git commit -m "refactor: make AppColors dynamic to support live theme updates"
```

---

### Task 2: Update AppTypography for Live Refresh

**Files:**
- Modify: `lib/core/themes/theme_tokens.dart` (AppTypography section)

- [ ] **Step 1: Ensure AppTypography getters use the now-dynamic AppColors**

(The existing code already uses `AppColors.textSecondary` and `AppColors.textPrimary` in its getters. Since we made those dynamic in Task 1, this task is primarily verification and ensuring no static caching occurs.)

- [ ] **Step 2: Commit**

```bash
git add lib/core/themes/theme_tokens.dart
git commit -m "style: ensure typography respects dynamic theme colors"
```

---

### Task 3: Final Root App Integration

**Files:**
- Modify: `lib/core/app_root.dart`

- [ ] **Step 1: Ensure ShadApp rebuilds with correct theme metadata**

```dart
class _AppTheme extends StatelessWidget {
  final String initialRoute;
  const _AppTheme({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return ShadApp(
      key: ValueKey(themeManager.currentTheme.id), // FORCE REBUILD ON THEME CHANGE
      title: 'Stress Pilot',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      navigatorObservers: [AppNavigator.routeObserver],
      themeMode: themeManager.themeMode,
      theme: themeManager.currentShadTheme ?? themeManager.lightShadTheme,
      darkTheme: themeManager.currentShadTheme ?? themeManager.darkShadTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: initialRoute,
      builder: (context, child) {
        return ScaffoldMessenger(
          key: AppNavigator.scaffoldMessengerKey,
          child: child!,
        );
      },
    );
  }
}
```

- [ ] **Step 2: Run final analysis**

Run: `flutter analyze lib/`
Expected: No issues found!

- [ ] **Step 3: Commit**

```bash
git add lib/core/app_root.dart
git commit -m "feat: finalize live theme switching integration"
```
