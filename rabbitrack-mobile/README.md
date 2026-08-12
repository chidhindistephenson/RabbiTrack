# RabbiTrack Mobile

Android-only Flutter application for RabbiTrack field workflows.

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
