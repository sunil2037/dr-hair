---
name: flutter-testing
description: Plan and write reliable Flutter unit and widget tests for Dr Hair features, navigation, accessibility, and responsive states. Use when adding or verifying tests in flutter_app.
---

# Flutter Testing

- Mirror `lib/features` structure under `test/` and keep tests deterministic, offline, and independent of live services.
- Unit-test business rules and state transitions; widget-test visible behavior, validation, navigation intents, empty/loading/error states, and semantics.
- Use explicit finders and user interactions (`tap`, `enterText`, `pumpAndSettle`) instead of implementation-only assertions.
- Mock network and platform boundaries. Avoid real delays, external URLs, and golden tests that depend on machine fonts unless fixtures are controlled.
- Include compact-screen and large-text cases for layouts likely to overflow; assert important controls remain visible and reachable.
- Run the narrow test target first, then the full Flutter test suite for broad changes. Report failures separately from pre-existing failures.
