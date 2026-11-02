---
name: dr-hair-user-flow
description: Inspect, implement, or test Dr. Hair patient journeys from phone OTP login through profile, assessment, care, products, reviews, videos, and appointments. Use for end-to-end Flutter patient-flow tasks.
---

# Dr. Hair patient user-flow workflow

Use this skill for end-to-end patient app work. Do not use it for an isolated backend task or admin-panel-only task.

## 1. Map before changing

1. Inspect `git status --short --branch` in Flutter and any relevant backend repository. Preserve all existing modifications.
2. Read `README.md`, `API_DOCUMENTATION.md`, the relevant Flutter feature, and `../backend/docs/openapi.yaml`. For backend changes also read its README, API roadmap, and relevant module.
3. Trace router/guard → screen → Cubit/repository → API route → persistence/provider. Identify live API, local cache, and demo-fixture behavior.
4. Check loading, empty, validation, error/retry, authenticated, and signed-out states before designing changes.

## 2. Patient identity and privacy invariants

- Patient sign-in is phone + OTP. Do not add Guest Login, guest patient state, fake-success authentication, or silent demo fallback. Protect patient routes/deep links and return to the requested route after login.
- Never send a real OTP, create a real patient, submit a real assessment, book an appointment, alter production data, or deploy during verification unless the user explicitly authorizes that specific action.
- Mock OTP, media, appointment, and API boundaries in tests. Never log secrets, OTPs, bearer tokens, private keys, or patient health data.
- Scope patient cache by authenticated patient ID and clear sensitive state on sign-out/account switch. Never show fabricated progress records or doctor-reviewed notes as real.
- Do not invent clinic details, medical outcomes, reviews, doctor endorsements, or product claims. Label demo content or use a truthful empty/unconfigured state.

## 3. Implement in small slices

1. State the exact flow and files involved, then give a short ordered plan.
2. Complete the requested implementation; do not stop after analysis when implementation was requested.
3. Reuse existing architecture, Dio client, media upload API, GoRouter, theme tokens, and shared widgets. Do not create duplicate APIs/services.
4. Update OpenAPI/client tests for backend contract changes and check all consumers.
5. Check phone (including 320px width), tablet, and desktop layouts; ensure persistent navigation does not cover actions.

## 4. Verify

- Run focused widget/unit tests first, then `flutter analyze` and the full test suite for broad changes.
- Keep tests offline and deterministic; never call production endpoints.
- Investigate failures instead of deleting/skipping tests. Separate regressions, stale expectations, and pre-existing failures.
- If manually testing, use a local/mocked backend and distinguish mocked behavior from real API verification.

## 5. Finish with evidence

Report changed files, behavior, exact checks and results, unverified steps, and missing API/configuration. Review the diff for unrelated edits and secrets. Never claim an untested or mocked flow passed end-to-end.
