---
name: flutter-feature-architecture
description: Structure Dr Hair Flutter features with clear data, domain, and presentation boundaries using flutter_bloc, Dio, and GoRouter. Use when adding or refactoring app features, API flows, state management, dependency wiring, or navigation in flutter_app.
---

# Flutter Feature Architecture

## Project layout

Follow the existing feature-first structure:

```text
lib/features/<feature>/
  data/datasources/       API and persistence adapters
  data/models/            JSON and transport models
  data/repositories/      repository implementations
  domain/entities/        app-facing models, when the feature needs a domain layer
  domain/repositories/    repository contracts
  domain/usecases/        meaningful feature operations
  presentation/viewmodels/ Cubits and immutable states
  presentation/views/     route-level screens
  presentation/widgets/   feature-specific UI components
lib/core/                 shared networking, routing, theme, and widgets
```

Keep the architecture proportional to the feature. A small static view does not need a repository and use case. Add boundaries when they isolate an external dependency, business rule, or independently testable state transition.

## State and presentation

- Use `flutter_bloc` and Cubits for asynchronous feature state, following existing `HomeCubit`/`HomeState` conventions unless the feature has event-driven complexity that benefits from a Bloc.
- Model states explicitly: initial or idle, loading, success with data, and failure with a user-safe message. Preserve existing data during refresh when useful; avoid representing unrelated states with several booleans.
- Keep Cubits focused on feature operations. Do not put widget context, navigation, formatting, or presentation-only animation state in a Cubit.
- Provide dependencies through a clear composition point (app/router/feature scope). Do not construct network clients or repositories inside screen builds.
- Keep views responsible for rendering state and forwarding user intent. Extract repeated feature patterns into presentation widgets with typed inputs.
- Make state immutable and implement `copyWith` or sealed states carefully, including a deliberate way to clear nullable error values.

## API and data flow

Use a predictable flow for remote data:

```text
View -> Cubit -> Use case (when useful) -> Repository contract
     -> Repository implementation -> Data source -> shared DioClient
```

- Reuse the configured `DioClient`; keep endpoint construction, request/response parsing, and transport details in data sources/models.
- Parse JSON defensively. Convert transport models to domain entities at the repository boundary when the feature has a meaningful domain model.
- Map Dio and parsing errors into typed, user-safe failures. The presentation layer should offer retry or recovery where appropriate.
- Never swallow an API error and silently return demo data. Mock or curated fallback data must be explicitly selected for development/demo use and clearly separated from production behavior.
- Do not log credentials, authorization headers, personal health information, or request bodies containing sensitive data. Configure interceptors for safe, redacted diagnostics.
- Keep cache and offline policy explicit. Avoid adding retry loops, persistence, or optimistic updates without a defined product behavior.

## Navigation

- Use GoRouter route names from `core/routes/route_names.dart`; keep route registration centralized in `AppRouter`.
- Use `StatefulShellRoute` branches for persistent top-level navigation and standalone `GoRoute`s for pushed full-screen flows.
- Pass small, typed navigation arguments and validate route extras at the boundary. For durable or shareable destinations, prefer path/query parameters over opaque in-memory objects.
- Keep navigation decisions in the presentation layer. Do not store `BuildContext` in services, Cubits, or repositories.
- Preserve back behavior, deep links, authentication redirects, and shell visibility when adding routes.

## Quality checks

1. Unit-test Cubit transitions and repository/data-source behavior with fakes; keep tests deterministic and offline.
2. Widget-test loading, success, empty, failure, retry, and navigation behavior for user-facing flows.
3. Check cancellation/disposal and duplicate submissions for asynchronous operations.
4. Run formatting, `flutter analyze`, focused tests, then the full suite for shared architecture or routing changes.
5. Review logs and error messages for secrets or personally identifiable and health information.

For visual design, accessibility, animation, and rendering performance, also apply [Flutter UI Engineering](../flutter-ui-engineering/SKILL.md). For the detailed test workflow, see [Flutter Testing](../flutter-testing/SKILL.md).
