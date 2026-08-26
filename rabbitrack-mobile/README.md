# RabbiTrack Mobile

Android-only Flutter application for RabbiTrack field workflows.

## Offline Tester APKs

The app supports offline demo login without the Laravel API server. Use:

```text
owner@rabbitrack.local
secret-password
```

Other offline test accounts are listed in `../docs/offline-tester-guide.md`.

Current split release APK outputs:

- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

## Local API

The Android emulator reaches the Laravel API through:

`http://10.0.2.2:8000/api/v1`

Physical Android devices need the host machine's LAN IP instead. Pass it with
`RABBITRACK_API_BASE_URL`:

```powershell
flutter run -d android --dart-define=RABBITRACK_API_BASE_URL=http://YOUR-LAN-IP:8000/api/v1
```

## Run

```powershell
flutter run -d android
```
