---
name: flutter-professional-motion
description: Create smooth, professional Flutter animations and transitions for Dr Hair, including navigation, feedback, loading, and content reveal. Use when adding motion or refining animation quality in flutter_app.
---

# Professional Flutter Motion

## Motion principles
- Motion should explain a state change, preserve continuity, or direct attention. Keep decorative movement rare and subtle.
- Reuse a small motion language: gentle ease-out for entrances, ease-in for exits, and standard ease-in-out for state changes. Avoid springy or elastic motion unless it fits the interaction.
- Use short durations for controls and state feedback (roughly 120–220 ms), moderate durations for panels and route changes (roughly 220–360 ms), and longer timing only for meaningful staged content.
- Animate opacity and small transforms for entrances. Avoid large travel distances, repeated bouncing, flashing, or motion that delays a user's action.
- Prefer implicit animations for simple property changes. Use `AnimationController` for coordinated sequences or gesture-driven motion and dispose it correctly.

## Flutter implementation
- Use `AnimatedSwitcher`, `AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder`, or the existing GoRouter transition APIs when they fit the job.
- Keep keys stable and meaningful so `AnimatedSwitcher` and lists transition the intended child instead of rebuilding unrelated content.
- Avoid animating expensive full-screen trees, intrinsic sizing, large shadows, or long lists. Animate a small subtree and profile if the screen is complex.
- Make transitions interruptible and safe during rapid taps, route changes, and widget disposal. Do not use timers as substitutes for animation lifecycle.
- Check `MediaQuery.disableAnimationsOf(context)` and remove or simplify non-essential motion when animations are disabled.
- Preserve semantics, focus, hit testing, and readable contrast in every animation state; motion must never be required to understand status.

## Review checklist
- Does the motion communicate a real state or relationship?
- Is the duration and direction consistent with similar interactions?
- Can users act immediately, including during rapid repeated input?
- Is reduced-motion behavior clear and complete?
- Does the animation avoid avoidable rebuilds, layout shifts, and frame drops?
- Are success, error, loading, and reverse transitions covered by tests when behavior warrants it?
