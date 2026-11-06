# ICA 13B: Firebase Authentication in Flutter

**Student:** Uyiosa Nehikhuere
**Course:** CSC 4360 Mobile App Development, Section B, Georgia State University
**Activity:** In-Class Activity #13B, Firebase Authentication (Undergraduate track)

A Flutter app that lets a user register, sign in, view a protected profile showing their email, change their password, and sign out. Firebase Authentication (email/password) manages credentials; the app never stores passwords.

## Implemented features

| Requirement | Where |
| --- | --- |
| Firebase initialized before `runApp()` with `DefaultFirebaseOptions.currentPlatform` | `lib/main.dart` |
| `AuthService`: register, sign in, sign out, password update, current user getter, cached `authStateChanges` stream | `lib/services/auth_service.dart` |
| Auth state routing: signed in shows Profile, signed out shows Sign in | `lib/screens/auth_gate.dart` |
| Registration and sign-in forms with email format check, 6 character minimum, confirm password | `lib/screens/authentication_screen.dart`, `lib/services/validators.dart` |
| Loading indicators and disabled buttons while requests run (no duplicate submits) | both screens |
| Firebase errors translated to safe messages; sign-in failures never reveal whether an email is registered | `AuthService.messageFor` |
| `ProfileScreen` shows current email, account created and last sign-in times, sign out | `lib/screens/profile_screen.dart` |
| Password update with `requires-recent-login` recovery: asks for current password, reauthenticates with `EmailAuthProvider.credential`, retries | `ChangePasswordDialog` |
| Session restoration: on relaunch the auth stream restores the signed-in user | `AuthGate` |

Optional Firestore extension: not implemented.

## Project structure

```
lib/
  main.dart                      Firebase init + MaterialApp(home: AuthGate)
  services/auth_service.dart     All FirebaseAuth calls + error translation
  services/validators.dart       Client-side form validation
  screens/auth_gate.dart         StreamBuilder on authStateChanges
  screens/authentication_screen.dart  Sign in / Register form
  screens/profile_screen.dart    Protected profile + change password dialog
test/validators_test.dart        Unit tests for validation and error messages
setup.ps1                        One-step Windows setup and APK build
```

## Setup

### 1. Firebase Console
1. Create a project at https://console.firebase.google.com/
2. Authentication > Sign-in method > enable **Email/Password**.

### 2. Local setup (Windows, automated)
```powershell
git clone <this repo>
cd ica13b-firebase-auth
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```
The script generates the Android folder, adds `<uses-permission android:name="android.permission.INTERNET" />` directly inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`, sets `minSdk` to 23, installs packages, runs `flutterfire configure` (pick your project and Android), runs the tests, and builds the release APK.

### 2b. Manual setup (any OS)
```bash
flutter create --platforms=android --project-name ica13b_firebase_auth --org edu.gsu.csc4360 .
# add the INTERNET permission to android/app/src/main/AndroidManifest.xml
# set minSdk = 23 in android/app/build.gradle(.kts)
flutter pub get
npm install -g firebase-tools && firebase login
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android
```

### Required Firebase configuration
`flutterfire configure` generates `lib/firebase_options.dart` and `android/app/google-services.json`. Both are listed in `.gitignore`, so each developer must generate their own. The app will not compile until `lib/firebase_options.dart` exists.

No passwords, signing keys, or service account credentials are committed.

## Run and test

```bash
flutter run                    # debug on an emulator or device
flutter test                   # unit tests
flutter build apk --release    # build/app/outputs/flutter-apk/app-release.apk
```

The release build uses Flutter's default debug signing config, which is fine for coursework. For a store release, follow https://docs.flutter.dev/deployment/android and keep `key.properties` and the keystore out of git.

### Manual test plan

| # | Action | Expected |
| --- | --- | --- |
| 1 | Register a new test account | Lands on Profile showing that email; user appears in Firebase Console > Authentication > Users |
| 2 | Sign out | Returns to Sign in; Profile is no longer reachable (back button does nothing) |
| 3 | Sign in with correct credentials | Profile shows email |
| 4 | Submit `bad-email` / 5 char password | Inline validation errors, no request sent |
| 5 | Sign in with wrong password | "Email or password is incorrect." |
| 6 | Register an email that already exists | "An account already exists..." |
| 7 | Change password | Snackbar confirms update |
| 8 | Sign out, sign in with old password | Fails with generic message |
| 9 | Sign in with new password | Succeeds |
| 10 | Close and relaunch app while signed in | Opens directly on Profile (session restored) |
| 11 | Airplane mode, then sign in | "Network error..." with spinner shown during attempt |
| 12 | requires-recent-login | If triggered (sign in, wait, then change password), dialog asks for current password and retries |

## References
- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Firebase Auth for Flutter: https://firebase.google.com/docs/auth/flutter/start
- Manage users (update password, reauthenticate): https://firebase.google.com/docs/auth/flutter/manage-users
- Flutter form validation: https://docs.flutter.dev/cookbook/forms/validation

## AI disclosure
Claude (Anthropic), November 6, 2026, was used to help scaffold the code and README. All behavior was tested by the student on a device/emulator; see the evidence document for results.
