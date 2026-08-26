# RabbiTrack Offline Tester Guide

This guide is for early farm testers using the Android APK without the RabbiTrack API server.

## Install

Use the APK that matches the device:

- Most modern Android phones: `rabbitrack-mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Older ARM Android phones: `rabbitrack-mobile/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- Android emulator on x64: `rabbitrack-mobile/build/app/outputs/flutter-apk/app-x86_64-release.apk`

## Offline Login

All offline test accounts use the same password:

```text
secret-password
```

Available accounts:

```text
owner@rabbitrack.local
admin@rabbitrack.local
manager@rabbitrack.local
worker@rabbitrack.local
vet@rabbitrack.local
viewer@rabbitrack.local
```

Usernames also work:

```text
owner
admin
manager
worker
vet
viewer
```

After login the app opens the seeded `RabbiTrack Demo Farm`. Testers can switch to `Empty Offline Farm` from account farm access if they want to start with no starter records.

## What To Test

Please test the normal farm workflow:

1. Open the dashboard and check whether the farm summary makes sense.
2. Add a rabbit and confirm it appears in the rabbits list and profile.
3. Add a location and confirm it appears in location pickers.
4. Create a mating record and confirm it appears under breeding.
5. Record a pregnancy check from the breeding flow.
6. Record kindling with litter birth weight.
7. Wean a litter and check the litter profile.
8. Create, reschedule, complete, and cancel tasks.
9. Add a health record and treatment.
10. Add a sale and expense, then check the finance report.
11. Try account reset with `Reset offline records`.

## Feedback Questions

Ask testers to fill in `docs/tester-feedback-form.md`, or use these quick questions:

- Which workflow felt easiest?
- Which workflow felt confusing?
- Were any rabbit farming terms unclear?
- Did any button or screen lead somewhere unexpected?
- Did the app ever show an API/server error while using offline mode?
- What information would they want on the dashboard first?
- Would they use this app during a normal day on the farm?

## Known Offline Behavior

- Offline records are saved locally on the device.
- The APK does not need Docker, Laravel, PostgreSQL, Redis, Mailpit, or internet for the offline demo.
- Google sign-in still requires proper Google configuration and network access, so testers should use the offline email/password accounts.
- `Reset offline records` clears only local changes for the selected offline farm. Demo starter records remain available.
