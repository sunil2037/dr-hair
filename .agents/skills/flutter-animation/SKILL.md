---
name: flutter-animation
description: Add polished, efficient Flutter motion in Dr Hair screens while preserving accessibility and reduced-motion preferences. Use when implementing transitions, animated feedback, loading states, or micro-interactions in flutter_app.
---

# Flutter Animation

- Prefer implicit widgets (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedOpacity`) for simple state changes.
- Use explicit controllers only when timing, sequencing, gestures, or disposal needs require them; always dispose controllers.
- Keep transitions short and purposeful, avoid animating layout-heavy trees or continuously rebuilding large lists.
- Respect `MediaQuery.disableAnimationsOf(context)` and provide a stable non-animated state when motion is disabled.
- Animate only meaningful changes; preserve hit targets, semantics, focus, and text readability throughout transitions.
- For route transitions, follow the existing GoRouter patterns and avoid custom animation dependencies without a demonstrated need.
- Verify state changes, rapid taps, navigation away during animation, and reduced-motion behavior with widget tests when requested.
