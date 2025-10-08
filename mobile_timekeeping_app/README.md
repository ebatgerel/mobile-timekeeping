# Mobile Timekeeping App (Flutter)

This is the Flutter client for the Mobile Timekeeping project. It currently includes a basic role selection and placeholder screens for Manager and Worker flows per the top-level requirements.

## Prerequisites
- Flutter SDK (3.22+)
- Xcode (for iOS) / Android Studio + Android SDK (for Android)

## Quick start (macOS)
1) Install Flutter and set up env (skip if already done):
   - https://docs.flutter.dev/get-started/install/macos
   - Run `flutter doctor` and fix any issues.
2) From the repo root:
   - `cd mobile_timekeeping_app`
   - `flutter pub get`
   - Run iOS Simulator or Android Emulator
   - `flutter run`

If Flutter isn't on PATH yet, see the bootstrap script below.

## Structure
- `lib/main.dart`: App entry with role selection and placeholder menus
- Future modules:
  - Auth (user registration)
  - Time tracking (clock-in/out, list)
  - Leave requests (create/approve)
  - Chat with file uploads
  - Manager reports (weekly, Excel export)
  - Map sectors for work areas

## Development notes
- Use Material 3, follow `flutter_lints`.
- Keep features modular with simple navigation first; replace placeholder tiles with actual screens.

## Bootstrap script (optional)
If `flutter` isn't on PATH, the script tries to source your Flutter SDK and run pub get.

Run:

```sh
./scripts/bootstrap.sh
```

Then run the app as above.