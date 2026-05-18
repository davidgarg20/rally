# Rally Mobile

Flutter app for the Rally badminton-rating MVP (iOS + Android).

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run against local backend

Start the backend (`backend/`) on port 8000, then:

```bash
# iOS simulator (host networking just works)
flutter run --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator (10.0.2.2 maps to host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Dev mode bypasses real Firebase: enter any 10-digit phone, then OTP `123456`.

## Screens

- Onboarding (phone, OTP, profile setup)
- Home (rating card, pending validations, recent matches)
- Log a match (singles/doubles wizard)
- Match detail (confirm/dispute)
- Leaderboard (Bangalore, singles/doubles, gender filter)
- Profile (stats, rating-history chart, sign out)

## Tests

```bash
flutter test                         # unit + widget
flutter test integration_test/       # against running backend
```
