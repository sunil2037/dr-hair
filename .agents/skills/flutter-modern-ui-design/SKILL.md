---
name: flutter-modern-ui-design
description: Design and refine modern, polished Flutter screens for the Dr Hair app with clear hierarchy, consistent visual systems, responsive layouts, and reusable components. Use when creating a screen or refreshing the visual design of an existing Flutter feature.
---

# Modern Flutter UI Design

## Visual direction
- Start from the product's existing identity in `AppColors`, `AppTheme`, Lucide icons, typography, and assets. Extend those tokens deliberately instead of introducing one-off colors and radii.
- Establish a clear hierarchy: one primary action per view, concise section headings, readable body copy, and restrained supporting detail.
- Use spacing and alignment consistently. Prefer a small spacing scale and shared card, field, button, and section patterns over screen-specific decoration.
- Keep surfaces calm and purposeful. Use contrast, borders, elevation, and accent color sparingly; gradients and shadows should clarify grouping or focus.
- Keep layouts adaptive across narrow phones, tablets, orientation changes, large text, and keyboard visibility. Use constraints and scrolling instead of fixed screen coordinates.
- Preserve the React screen's content and behavior when porting it. Improve Flutter ergonomics without silently removing states or actions.

## Components and interaction
- Build reusable widgets around stable design patterns and explicit inputs. Keep screen composition in the feature and broadly shared primitives in `lib/core/widgets`.
- Use Lucide icons consistently. Pair icon-only actions with tooltips and semantic labels, and use text alongside unfamiliar actions.
- Provide clear loading, empty, error, disabled, selected, and success states. Avoid layout shifts when state changes or images load.
- Keep controls reachable and comfortably tappable; include visible keyboard focus and pressed feedback where relevant.
- Respect safe areas, system bars, text scaling, localization growth, and contrast. Do not encode meaning through color alone.

## Workflow
1. Read the related React screen, Flutter implementation, and existing theme before proposing a visual change.
2. Identify the screen's main task, content priority, data states, and repeated patterns.
3. Reuse current tokens and components; add a shared primitive only when it has a clear second use or improves consistency.
4. Check compact width and increased text scale, then verify that content remains scrollable and actions reachable.
5. When visual verification is available, compare the rendered Flutter screen with the reference at the same viewport and iterate on spacing, alignment, typography, and image crop.
