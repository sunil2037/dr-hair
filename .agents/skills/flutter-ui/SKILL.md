---
name: flutter-ui
description: Build and review Dr Hair Flutter UI with reusable, responsive widgets, accessible controls, and safe area handling. Use when changing screens, layouts, navigation chrome, or shared presentation components in flutter_app.
---

# Flutter UI

## Project conventions
- Keep code under `lib/features/<feature>/{presentation,domain,data}` and shared presentation primitives under `lib/core/widgets`.
- Extract repeated visual patterns into small, immutable widgets with explicit inputs; keep feature-specific compositions inside the feature.
- Use `AppColors`, `AppTheme`, and existing asset paths. Avoid introducing a second palette or inline network images when a project asset exists.
- Support narrow phones, large text, and keyboard insets. Use `SafeArea` or `MediaQuery.paddingOf(context)` at screen edges; do not apply the same inset twice.
- Prefer constraints, `Expanded`, `Flexible`, and scroll views over fixed screen dimensions. Preserve intentional image aspect ratios.
- Use buttons with tooltips and semantic labels for icon-only actions. Keep touch targets comfortably sized and expose selected/disabled states.
- Keep text scalable; avoid clipping with fixed heights and `maxLines` unless truncation is part of the design.

## Workflow
1. Read the matching React screen and the current Flutter counterpart before editing.
2. Identify shared behavior, data states, and layout breakpoints.
3. Make the smallest coherent component extraction or screen change.
4. Run formatting, analyzer, and focused widget tests when the task asks for validation.
5. Inspect the final diff for duplicated insets, overflow-prone fixed sizing, and unlabeled controls.
