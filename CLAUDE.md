# StressPilot UI Overhaul — Agent Instructions

## User input raw
i currently have project page (which contains runs, recent activity), workspace, endpoint management page, settings page, plugins page with webview to my plugin cms

i want to do like if nothing found i shared preference about last project, we show recent activity
else we show the project workspace immidiately

the workspace shall have the left side like code files for Fleet but now is endpoints, when clicking the endpoints, it shows a tab that we can call the api, like we move the endpoint management page to separate ones

Also, we will also be able to CRUD flows there, and option to CRUD the environment variables (it should be top right), under the navigation bar at top, the navigation bar should have marketplace, settings and the agent button, clicking on a flow will open the canvas to drag endpoints and drop them, link them together to save

All components are pages are done but the page connection and the way workspace work will be changed, behaviours of the other pages stays the same, adhere to feature first architecture (ref current folder struct before refactor) (for example, what is in the code is functional and it should stay the same, only the layout or page flow changes)

Also ref and search Jetbrains Fleet design and color, style before doing anything to the code, plan ahead before writing code, dont write too many comments, just that if code get's too long, we can separate by block and add comment to show what it does, apply skill sets that can design and copy Jetbrains Fleet

## Mission

Re-skin the entire app to match JetBrains Fleet's visual language. Every screen, every widget, every component gets touched. **Functionality does not change** — no logic, no state, no data fetching, no API calls. Only how things look.

Think of this as a painter pass over the whole codebase: same structure, new coat.

---

## Before writing any code

1. Scan the full project folder structure to understand current feature-first layout.
2. Search the web for "JetBrains Fleet UI design", "JetBrains Fleet color palette", and "JetBrains Fleet editor screenshot". Study the results. Extract:
   - Background colors (near-black base, panel surfaces, sidebar)
   - Accent colors (muted indigo/purple)
   - Text hierarchy (primary, secondary, disabled)
   - Border and elevation treatment (color-shift only, no shadows)
   - Sidebar chrome, tab bar, toolbar patterns
   - Spacing and density
   - How selected/active/hover states look
3. Write a **design token file** (`lib/core/theme/fleet_tokens.dart` or equivalent) with all extracted values: colors, text styles, radii, spacing constants. Every visual value in the app must reference this file — no hardcoded hex anywhere else.
4. Write a migration plan listing every file that will change. Get confirmation before proceeding.

---

## Architecture rules

- **Feature-first structure is preserved.** Do not reorganize folders.
- **No logic changes.** State, business logic, API calls, data models, form validation — all untouched.
- **No new dependencies** unless strictly needed for a layout primitive already in use.
- All colors, text styles, and spacing come from the token file. No inline styling that isn't already there.

---

## Design system — Fleet

These rules apply to **every single widget in the app**, not just the workspace. Go through all screens.

### Colors

- Base background: `#1e1f22`
- Sidebar / panel surface: `#23242a` (slightly lighter)
- Elevated surface (dialogs, popovers): `#2b2c33`
- Active / selected item bg: `#383a47`
- Hover bg: `#2e2f38`
- Accent (primary actions, active icons, selected tabs): `#7b68ee` (muted indigo — adjust to what you find in Fleet screenshots)
- Accent hover: slightly lighter
- Border: `rgba(255,255,255,0.08)` — used sparingly
- Text primary: `#dcd9d0` (off-white, never pure white)
- Text secondary: `#7e7c75` (~55% opacity equivalent)
- Text disabled: `#4a4845` (~30%)
- Destructive: muted red, not bright
- Method badge colors: GET `#57a64a`, POST `#4b8fd4`, PUT `#c8a84b`, DELETE `#c25151`, PATCH `#8b68d4`

### Typography

- UI chrome: system sans-serif (SF Pro / Roboto / Inter depending on platform)
- Code, paths, keys, values: monospace
- Sizes: 11px for labels/badges, 13px for body, 14px for active/selected/headings
- Weights: regular for body, medium (500) for active items and headings — nothing heavier
- Line height: tight, 1.3–1.4

### Surfaces and elevation

- No `BoxDecoration` shadows anywhere. Remove all existing drop shadows.
- Elevation = background color only. A dialog is elevated because it's `#2b2c33` on `#1e1f22`, not because it has a shadow.
- Dividers: 1px `rgba(255,255,255,0.06)`, only where structurally necessary.

### Radius

- Buttons, inputs, small chips: 4px
- Panels, cards, dialogs: 6px
- Pill badges (method labels): full radius
- Nothing larger than 8px

### Density

- Sidebar rows: 32px tall, 8px horizontal padding
- Tab bar height: 36px
- Toolbar/nav bar: 40px
- Form fields: 32px tall
- List items: 32–36px
- Dialog padding: 16px
- Section gaps: 12px, not 24px — Fleet is tight

### Interactive states

- Hover: add subtle dark tint background
- Selected/active: `#383a47` background + accent-colored left border (2px) or accent text
- Pressed: slightly darker than hover
- Disabled: text at 30% opacity, no background change
- Focus: thin accent-colored outline, 1px

### Icons

- Size: 16px throughout. 20px only for primary action buttons.
- Inactive: secondary text color
- Active / selected: accent color
- Use whatever icon set is already in the project — do not swap icon libraries

### Buttons

- Primary: accent background, primary text, 4px radius, no shadow
- Secondary: transparent background, border `rgba(255,255,255,0.12)`, secondary text
- Destructive: muted red background
- Icon buttons: no background unless hovered, then hover bg
- No rounded pill buttons except for method badges

### Inputs and forms

- Background: `#2b2c33`
- Border: `rgba(255,255,255,0.1)` at rest, accent color on focus
- Text: primary color
- Placeholder: secondary color
- Height: 32px
- No floating labels — use static labels above inputs

### Dialogs and sheets

- Background: `#2b2c33`
- No scrim or very dark subtle scrim (`rgba(0,0,0,0.6)`)
- Title: 14px medium, primary text
- Body: 13px regular, secondary text
- Action buttons at bottom-right, text buttons only (no filled button bar)

### Empty states

- Centered, icon (32px, secondary color) + short label (13px secondary) + optional action link
- No illustration bloat

### Scrollbars

- Thin (4px), thumb color `rgba(255,255,255,0.15)`, no track background

---

## App launch flow

```
on launch:
  if SharedPreferences has a saved last project →
    navigate directly to Workspace for that project
  else →
    show Recent Activity screen
```

Use the key the app already writes on project open. Do not add a new key.

---

## Workspace layout

### Top navigation bar (40px)

- Left: project name, 13px secondary text
- Right: Marketplace · Settings · Agent — text buttons, no backgrounds, secondary text, accent on hover

### Environment variables badge

Below the nav bar, top-right of the content area. Opens existing env var UI unchanged.

### Left sidebar

Fleet-style file tree, but for endpoints:

- Groups collapsible, group label 11px uppercase secondary text
- Endpoint rows: method badge (pill, 10px monospace) + path (13px monospace, secondary)
- Selected row: `#383a47` bg + accent left border
- Hover: `#2e2f38` bg
- Add button at top of list (+ icon, 16px, secondary color, accent on hover)
- Edit/delete on hover (icon buttons, appear on row hover)

Second collapsible section below: Flows list, same density.

### Tab bar (36px)

- Inactive tab: 13px secondary text, no background, border-bottom transparent
- Active tab: primary text, accent border-bottom (2px)
- Close button (×) appears on hover, 16px, secondary color
- Tab bar background: same as sidebar (`#23242a`)

### Main content area

- Background: `#1e1f22`
- Endpoint tab: existing request/response UI, re-skinned to match tokens
- Flow canvas: dark canvas bg, draggable endpoint nodes (elevated card surface), connector lines in secondary color

### Empty tab state

Centered: "Select an endpoint or open a flow" — 13px secondary text, no illustration

---

## All other screens — apply the same token pass

Go through every screen in the app and apply the same token rules:

- **Recent Activity screen:** dark list, same density, secondary timestamps
- **Settings page:** form fields and section headers re-skinned, no logic change
- **Plugins / Marketplace page:** cards re-skinned, same grid/list structure
- **Env var management:** table/list re-skinned, inputs match token spec
- **Any modal or bottom sheet:** elevated surface, no shadow

The goal: every screen looks like it belongs to the same app and that app looks like Fleet.

---

## What is removed / consolidated

- Standalone Endpoint Management page as a top-level route → removed, lives in sidebar + tabs now
- Project landing page → replaced by Recent Activity or direct Workspace entry
- All drop shadows, all gradients, all decorative borders
- Any bottom nav or drawer items pointing to removed routes
- All hardcoded color values → moved to token file

---

## Code style

- Comments only at block boundaries when a section is non-obvious
- Files over ~200 lines: split by logical block with a single-line section comment
- No dead code. Remove unreachable routes, widgets, imports.
- Match existing formatting and naming conventions per file

---

## Order of operations

1. Read full folder structure and all existing routes
2. Search web for Fleet design references, write findings
3. Create `fleet_tokens.dart` (or equivalent) with all design tokens
4. Write migration plan (every file changing, every file untouched) — wait for confirmation
5. Apply theme/token file globally (one pass, no layout changes yet)
6. Implement launch flow
7. Implement workspace shell (nav bar, sidebar, tab container)
8. Wire endpoint sidebar → endpoint tabs
9. Wire flow list → flow canvas tabs
10. Implement env var badge
11. Re-skin remaining screens (settings, plugins, recent activity, env vars, dialogs)
12. Remove obsolete routes and dead code
13. Smoke-test every nav path
