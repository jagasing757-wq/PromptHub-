# PromptHub

PromptHub - simple Prompt Collection app for AI image prompts.

## What's included
- Flutter app (lib/main.dart)
- pubspec.yaml with required dependency
- GitHub Actions workflow to build signed APK automatically (requires keystore secrets)
- Simple placeholder app icon in `assets/`

## How to use
1. Create a GitHub repository and upload these files (or push via git).
2. Add Secrets in Settings → Secrets → Actions:
   - KEYSTORE_BASE64 : base64 content of your `.jks` file
   - KEYSTORE_PASSWORD
   - KEY_ALIAS
   - KEY_PASSWORD
3. Push to `main` branch. GitHub Actions will build the signed APK and create a Release with the APK.
4. Download the APK from Releases and install on your Android phone.

If you want, I can also:
- Add password-protected Admin mode
- Connect to Firebase for cloud sync
- Create Play Store listing draft

Tell me which next step you want and I'll do it.
