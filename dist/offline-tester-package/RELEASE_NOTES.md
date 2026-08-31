# RabbiTrack Offline Tester Build

## Purpose

This build is for early Android farm testing without requiring the RabbiTrack API server.

## Included APKs

- `app-arm64-v8a-release.apk` - most modern physical Android phones.
- `app-armeabi-v7a-release.apk` - older ARM Android phones.
- `app-x86_64-release.apk` - Android x64 emulators.

## Offline Login

```text
Email: owner@rabbitrack.local
Password: secret-password
```

Other tester accounts are listed in `docs/offline-tester-guide.md`.

## Highlights

- Offline demo farm with starter records.
- Empty offline farm option for clean testing.
- Offline rabbit, litter, breeding, health, task, location, sales, expense, and report flows.
- Local reset option for offline records.
- Tester guide, QA checklist, and feedback form included.

## Notes

- No Docker, Laravel API, PostgreSQL, Redis, Mailpit, or internet is required for offline demo testing.
- Google sign-in still requires proper Google configuration and network access, so testers should use email/password.
