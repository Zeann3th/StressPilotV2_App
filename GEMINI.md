# StressPilot Engineering Standards & Fleet UI Mandates

## Core Principles
- **JetBrains Fleet Aesthetic:** Strictly adhere to the Fleet design language (dark near-black backgrounds, muted indigo accents, no shadows, 1px borders).
- **Icon-Priority UI:** Never use text for actions unless no standard icon exists. Show text ONLY on hover (tooltips).
- **Surgical Changes:** Minimize diff size. Keep functionality and logic untouched.
- **Continuous Validation:** ALWAYS run `flutter analyze lib/` after EVERY code modification. No exceptions. Fix all errors before proceeding.

## Design Tokens (lib/core/themes/theme_tokens.dart)
- **Base BG:** `#1E1F22`
- **Sidebar BG:** `#23242A`
- **Surface:** `#2B2C33`
- **Active:** `#383A47`
- **Accent:** `#7B68EE`
- **Radius:** 4px (buttons/inputs), 6px (panels/cards).

## UI Component Rules
- **Sidebar:** Folder titles must have a `v` or `>` arrow. Children must be indented (e.g., 16px-24px).
- **Top Navigation:** Central project title must be truly centered to the screen, not relative to adjacent icons. Use `Stack` or `Expanded` spacers.
- **Environment Page:** Icons only for CRUD actions. Search bar must be long (min 300px) and centered.
- **Spacing/Padding:** Use `AppSpacing` tokens. Never use arbitrary hardcoded padding. Fleet uses tight spacing (32px rows, 12px gaps).

## Forbidden Patterns
- **No File Loggers:** Remove any code that writes to local files or verbose debug print systems. Use `AppLogger` only.
- **No Shadow/Elevation:** Remove all `BoxShadow`, `elevation`, and `PhysicalModel` widgets.
- **No Text Buttons:** Replace `PilotButton(label: '...')` with icon-only variants if used for global actions.

## Skill Requirement
Activate and follow the `fleet-design-system` skill for all UI tasks.
