# Dr. Hair Flutter app guidance

- Read `README.md`, `API_DOCUMENTATION.md`, and the relevant feature code before changing a user flow. The API contract lives at `../backend/docs/openapi.yaml`; check it before changing requests or responses.
- Follow the feature-first architecture, Flutter Bloc/Cubit state patterns, shared Dio client, and GoRouter conventions already used in this app. Prefer existing shared widgets, theme tokens, and media upload services over new parallel implementations.
- Patient sign-in is the real phone + OTP flow. Do not add Guest Login, fake successful authentication, or silent demo fallback. Keep protected routes and patient API calls behind a valid session.
- Keep patient data scoped to the authenticated patient. Clear sensitive in-memory state on sign-out/account switch. Never seed fake doctor-reviewed notes, fabricated patient history, or unverified medical claims into real-user flows.
- Keep tests deterministic and offline. Mock OTP, media, API, and appointment boundaries; never call production services or use real patient data in tests.
- Check Web, narrow phone, tablet, and desktop layouts for affected screens. Fix layout constraints instead of clipping overflow.
- Run the focused test target first, then `flutter analyze` and the full Flutter suite for broad changes. Review the diff and report pre-existing failures separately.
- For UI work also follow `.agents/skills/flutter-ui-engineering/SKILL.md`; for architecture use `.agents/skills/flutter-feature-architecture/SKILL.md`; for tests use `.agents/skills/flutter-testing/SKILL.md`.
