# Dr Hair Flutter app

## Run against the local API

Start the Express backend on port `5001`, then choose a URL reachable from the device:

```bash
# Flutter web or iOS simulator
flutter run -d chrome --dart-define=DRHAIR_BACKEND_URL=http://localhost:5001

# Android emulator
flutter run --dart-define=DRHAIR_BACKEND_URL=http://10.0.2.2:5001
```

For a physical device, use the computer's LAN address and allow that origin in backend `CORS_ORIGINS`. Production builds must pass the deployed HTTPS API origin through `DRHAIR_BACKEND_URL`.

## API documentation

The canonical OpenAPI contract is in `../backend/docs/openapi.yaml` and is served by the backend at `/api/openapi.yaml` (interactive docs: `/api/docs`). Flutter integration notes are in [API_DOCUMENTATION.md](./API_DOCUMENTATION.md).

OTP verification returns the registered profile in the same response; restoring a session returns the profile in one request. Media uses the authenticated `POST /api/v1/media/upload` multipart endpoint for up to five mixed images/videos per request, then each returned URL is saved through the relevant profile/content API.
