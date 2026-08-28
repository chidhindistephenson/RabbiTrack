# RabbiTrack Offline QA Checklist

Use this checklist before sending a tester APK to a farm user.

Run the automated non-build checks from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-offline-mobile-checks.ps1
```

If the analyzer gets slow on a low-resource machine, run only the focused tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-offline-mobile-checks.ps1 -SkipAnalyze
```

## Setup

- Install the latest split APK for the device.
- Turn off mobile data and Wi-Fi, or keep the phone away from the API server.
- Open RabbiTrack.
- Sign in with `owner@rabbitrack.local` and `secret-password`.
- Confirm the app opens `RabbiTrack Demo Farm`.
- Switch to `Empty Offline Farm` from account farm access.
- Confirm empty screens do not show API/server errors.
- Switch back to `RabbiTrack Demo Farm`.

## Dashboard

- Dashboard loads with starter demo data.
- Notification icon shows the task count badge.
- No task focus card appears on the dashboard.
- Finance values use `$`.
- Dashboard cards do not repeat the same action group.

## Rabbits And Litters

- Rabbits tab lists starter rabbits.
- Search is case-insensitive and allows continuous typing.
- Add rabbit saves offline and appears in the list.
- Rabbit profile opens for starter and newly-created rabbits.
- Sold rabbits are protected from actions that should not apply.
- Litters tab opens inside Rabbits.
- Litter profile opens and shows birth outcome, checks, fostering, weaning, and kit conversion controls.
- Litter-to-rabbit conversion creates rabbit records with system-generated IDs.

## Breeding

- Breeding list loads without API errors.
- Breeding calendar is available inside Breeding.
- Create mating saves offline and appears in Breeding.
- Duplicate active mating between the same doe and buck is blocked.
- Pregnancy check is only available after the configured check window.
- A pregnancy decision updates the breeding record locally.
- Delete hides the mating record locally.

## Health

- Health records load offline.
- Health report is available inside Health.
- Create health record saves offline.
- Add treatment saves offline.
- Status updates save offline.

## Tasks

- Task list loads offline.
- Create task saves offline.
- Complete task removes it from open task counts.
- Reschedule changes its due date locally.
- Cancel task removes it from open task counts.
- Task count badge updates after task changes.

## Finance

- Finance report opens from More.
- Overview, Sales, and Expenses are grouped under Finance report.
- Add sale saves offline and appears in the sales list.
- Add expense saves offline and appears in the expenses list.
- Export CSV actions do not require the API in offline demo mode.

## Account And Reset

- Account screen shows personal info and farm access.
- Farm settings, API status, and sign out are under Account.
- Switch farm is under Account farm access.
- Reset offline records clears local changes for the selected offline farm.
- Demo starter records remain after reset.

## Final Smoke Test

- Close and reopen the app.
- Confirm the saved offline session restores.
- Confirm locally-created records remain visible.
- Confirm there are no normal-flow API/server error messages.
