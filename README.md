# PromptHub (Online)

This repository is a Flutter app that shows AI image prompts with image preview and stores prompts online in Firebase Firestore.

## What you need to do (Firebase setup)
1. Create a Firebase project: https://console.firebase.google.com/
2. Add an Android app in Firebase (package name can be `com.example.prompthub_online`).
3. Download `google-services.json` and place it at `android/app/google-services.json` in this project.
4. Enable Firestore in Firebase console (create database in test mode initially).
5. If using Android, add the Firebase Android plugins as per FlutterFire docs. (See notes below.)

## Notes
- This repo currently contains only Flutter Dart code (lib/) and pubspec.yaml.
- To build an Android APK in GitHub Actions you need full Android folders. If you want Actions to build directly, run `flutter create .` locally (on PC) to generate android/ and ios/ folders, then push the full project to GitHub.
- Alternatively, I can prepare a full Flutter project including Android folders, but that increases ZIP size. Tell me if you want the full ready-to-build project.

## How the app works
- Prompts are stored in Firestore collection `prompts`. Document fields:
  - `prompt` (string)
  - `imageUrl` (string)
  - `createdAt` (timestamp)

- Open the app, it lists prompts from Firestore. Toggle Admin mode (top-right lock icon) to add/delete prompts.

## Building locally
1. Ensure Flutter SDK is installed.
2. Place `google-services.json` (Android) into `android/app/`.
3. Run:
   ```
   flutter pub get
   flutter run -d chrome   # or flutter run -d android
   ```

If you want, I can also:
- Add instructions to connect to Firebase automatically.
- Create the full Android project and upload the ready ZIP for direct GitHub Actions build.

