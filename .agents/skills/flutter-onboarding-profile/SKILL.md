---
name: flutter-onboarding-profile
description: Implement or review Dr Hair Flutter sign-in, first-run onboarding, account creation, and user profile flows, including API and route integration.
---

# Flutter Onboarding Profile

Use this skill when changing the patient sign-in journey, onboarding completion, profile setup/editing, or the route gates between them.

## Inspect the full flow

- Start at the splash route and trace the current sign-in, OTP, registration, profile, and home routes before changing behavior. Check `lib/core/routes/`, the relevant feature files, and existing tests.
- Read `../backend/docs/openapi.yaml` and the backend auth/user implementation before changing payloads or assumptions. Reconcile the implemented API with the published contract; do not assume either is current without checking both.
- Keep the app's feature-first structure and existing Cubit, repository, data-source, and shared Dio patterns. Views render state and forward user actions; they do not own HTTP or persistence logic.

## Identity and onboarding behavior

- A user is authenticated only after the server verifies the OTP and returns a valid session token. Do not mark a user signed in because a phone/email was entered or because a local OTP screen advanced.
- Use the server's registration/profile status to decide whether to show onboarding or the signed-in shell. Keep redirect decisions centralized in the router or auth state, and preserve back/deep-link behavior.
- Prefill editable profile fields from the authenticated profile. Keep required and optional fields aligned with the API contract; preserve entered data when a request fails so the user can retry.
- Store and clear session data through the existing persistence boundary. Do not log tokens, OTPs, phone/email values, or health information.
- Prevent duplicate OTP verification and profile submissions while requests are in flight. Provide clear retry paths for network, expired-code, and validation failures.

## Verify when requested

- Cover auth state transitions, first-time versus returning-user routing, profile validation and prefill, and request/response mapping with deterministic fakes.
- Follow [Flutter Feature Architecture](../flutter-feature-architecture/SKILL.md) and [Flutter Testing](../flutter-testing/SKILL.md) when those broader workflows apply.
