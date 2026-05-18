# Rally Mobile

Flutter app for the Rally badminton-rating MVP.

## Setup

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run -d <device>
```

The default backend URL is `http://localhost:8000` (dev). Override with:

```bash
flutter run --dart-define=API_BASE_URL=https://staging.rally.example
```

In dev, the app uses a fake Firebase identity: tap "Send OTP" → enter `123456` → you sign in as `dev:<random-uid>:<phone>` against the backend.

## Tests

```bash
flutter test                       # unit + widget tests
flutter test integration_test/     # on a device/emulator
```
