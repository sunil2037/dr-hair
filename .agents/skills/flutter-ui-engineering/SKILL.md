---
name: flutter-ui-engineering
description: Design, build, animate, and optimize production-quality Flutter interfaces for the Dr Hair app. Use when creating or revising screens, shared components, navigation, visual systems, animation, responsiveness, accessibility, rendering performance, or React-to-Flutter UI parity.
---

# Flutter UI Engineering

Use this skill for end-to-end Flutter presentation work. Deliver a coherent, working screen with consistent visuals, complete states, accessible behavior, and measured performance.

## 1. Inspect before editing

1. Read applicable project instructions and the relevant React source, Flutter screen, route, theme, assets, and shared widgets.
2. Trace the complete user path: entry point, actions, loading and error states, navigation result, and system insets.
3. Identify the existing design tokens and reusable patterns before choosing new ones. Preserve established copy and behavior during a port.
4. Check repository and toolchain availability before planning visual verification. Never claim pixel parity without rendering and comparing both implementations at the same viewport.

## 2. Design a cohesive interface

- Use `AppColors`, `AppTheme`, Lucide icons, and existing assets as the source of truth. Extend tokens in one shared location when the product needs a new value; avoid scattered one-off styling.
- Establish one clear primary action per screen, a visible content hierarchy, readable type, and consistent spacing, radii, borders, and elevation.
- Prefer calm surfaces and deliberate contrast. Use color, gradients, shadows, and decoration to express hierarchy or state, not as filler.
- Build screen-specific composition in `lib/features/<feature>/presentation`; put shared, stable primitives in `lib/core/widgets`.
- Give reusable widgets explicit inputs and keep state with the smallest owner that can manage the behavior. Avoid oversized screens that combine unrelated UI, data, and interaction logic.
- Preserve all reference content and actions. Account for success, validation, disabled, loading, empty, and failure states; provide useful feedback after user actions.

## 3. Responsive and accessible behavior

- Support compact phones, tablets, orientation changes, large text, keyboard visibility, localization growth, and right-to-left direction where relevant.
- Use constraints, flexible layouts, lazy lists, and scrolling instead of screen-sized fixed coordinates. Keep images at explicit dimensions/aspect ratios and handle loading and failure without layout shifts.
- Apply safe area and keyboard insets once at the correct boundary. Ensure floating controls do not cover content or actions.
- Use semantic labels and tooltips for icon-only actions, visible focus and pressed states, adequately sized touch targets, and selected/disabled semantics. Do not rely on color or animation alone to communicate meaning.
- Use the app's Lucide icon family consistently. Keep labels alongside unfamiliar or high-impact actions.

## 4. Motion language

- Animate only meaningful state changes, continuity, or focus. Keep motion subtle and interruptible; avoid decorative loops, bouncing, flashing, and delayed actions.
- Prefer implicit animation widgets for simple changes. Use controllers for coordinated or gesture-driven sequences and dispose them correctly.
- Use a consistent easing vocabulary: ease-out for entrances and feedback, ease-in for exits, and ease-in-out for transitions. Typical control feedback is 120–220 ms; panels and routes are 220–360 ms.
- Animate small subtrees and stable properties. Use keys where children change identity. Avoid animating full screen trees, intrinsic layout, large shadows, or long lists without profiling.
- Respect `MediaQuery.disableAnimationsOf(context)` by removing or simplifying non-essential motion. Keep semantics, focus, hit testing, and understandable state throughout transitions.

## 5. Performance engineering

- Optimize based on a reproducible issue or profile measurement. Use Flutter DevTools in profile mode for frame timing, rebuilds, raster work, memory, and image costs.
- Keep expensive work and repeated object creation out of frequently called `build` methods when it materially affects rendering. Use `const` and scoped state updates where they reduce real rebuild work.
- Build changing or long collections lazily (`ListView.builder`, slivers). Avoid nested unbounded scrollables and eagerly built off-screen content.
- Reuse cached network image components, set dimensions, preserve placeholders, and avoid refetching unchanged assets.
- Limit costly clipping, opacity layers, blur, shadows, and broad animations. Prefer a simple implementation until profiling demonstrates a bottleneck.
- Clean up controllers, listeners, subscriptions, and image/state resources. Validate improvements using the same scenario and compare before/after profile evidence.

## 6. Verify the result

1. Format changed Dart files, run `flutter analyze`, and run focused widget tests; run the full test suite when changes span features or shared infrastructure.
2. Test actual user interactions, route outcomes, empty/loading/error states, accessibility semantics, compact widths, and increased text scale where relevant.
3. Render the target screen at matching reference dimensions when visual tools are available. Compare spacing, alignment, text wrapping, image crop, system bars, and bottom insets; iterate on visible mismatches.
4. For performance work, record the scenario and compare profile data before and after. Do not claim performance improvements from code inspection alone.
5. Report completed changes, verification performed, unavailable tools, and any remaining parity gaps plainly.

## Dr Hair project structure

```text
lib/core/theme/                 shared colors and component themes
lib/core/widgets/               reusable app-wide presentation widgets
lib/features/<feature>/         feature-owned data, state, and screens
test/                            widget and behavior tests
```
