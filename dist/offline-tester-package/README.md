# RabbiTrack Offline Tester Package

Use this folder as the handoff index for early Android testers.

## APK To Share

For most physical Android phones, share:

```text
rabbitrack-mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Use these only when needed:

```text
rabbitrack-mobile/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
rabbitrack-mobile/build/app/outputs/flutter-apk/app-x86_64-release.apk
```

`app-armeabi-v7a-release.apk` is for older ARM phones.
`app-x86_64-release.apk` is mainly for Android emulators.

## Tester Login

Use this account first:

```text
Email: owner@rabbitrack.local
Password: secret-password
```

The app should work offline with no Docker, API server, internet, PostgreSQL, Redis, or Mailpit.

## Included Documents

- `docs/offline-tester-guide.md` - what testers need to install and use the app.
- `docs/tester-feedback-form.md` - questions to send after testing.
- `docs/offline-qa-checklist.md` - internal checklist before sharing an APK.

## Sharing Checklist

Before sending the APK:

1. Confirm the APK path exists.
2. Send the tester guide.
3. Send the login credentials.
4. Ask the tester to complete the feedback form.
5. Ask them to report any API/server error messages with screenshots.

## Prepare Local Package

After an APK has already been built, prepare a local share folder without
running another build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-offline-tester-package.ps1
```

To include all APK variants:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-offline-tester-package.ps1 -IncludeAllApks
```

Copied APKs, copied docs, and the package manifest are local share artifacts and
are intentionally ignored by git.
