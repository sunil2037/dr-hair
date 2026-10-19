---
name: flutter-performance
description: Diagnose and improve Flutter runtime and rendering performance in Dr Hair without reducing UI quality. Use when screens jank, lists or images are heavy, rebuilds are broad, or the user asks for performance work in flutter_app.
---

# Flutter Performance

- Measure before optimizing: reproduce the slow path and use Flutter DevTools in profile mode for frame timing, rebuilds, memory, and raster work.
- Keep large or changing collections lazily built (`ListView.builder`, slivers); avoid eagerly constructing long off-screen lists.
- Keep expensive work out of `build`; cache stable values, use `const` where possible, and scope state updates to the smallest subtree.
- Give remote images explicit dimensions and caching; handle loading and failure without repeated layout shifts.
- Avoid unnecessary opacity, clipping, shadows, and broad animations on large subtrees; profile before replacing readable code with complexity.
- Check lifecycle cleanup for controllers, subscriptions, and listeners. Confirm optimizations with the same scenario and compare profile results.
