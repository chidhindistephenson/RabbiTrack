# RabbiTrack

Rabbit farm management system for rabbit identification, breeding, litter, health, production, task, and farm-record management.

## Project Structure

- `rabbitrack-api` - Laravel backend, REST API, administration portal, migrations, queues, and backend tests.
- `rabbitrack-mobile` - Android-only Flutter mobile application with offline-first field workflows.
- `docs` - Product requirements, architecture notes, API contracts, and delivery planning.

## Approved Stack

- Backend: Laravel 13, Laravel Sanctum, PostgreSQL, Redis, queues, scheduler.
- Mobile: Flutter for Android, Riverpod, GoRouter, Drift/SQLite, Dio.
- Admin portal: Laravel, Inertia.js, Vue.js, Tailwind CSS.
- Local services: Docker Compose for PostgreSQL on host port `55432`, Redis, and Mailpit.

## First Milestone

The first development slice is identity and farm setup:

- users, farms, farm memberships, roles, and locations
- API authentication endpoints
- farm-scoped authorization
- audit-event groundwork
- Flutter login, farm selection, and home shell

## Mobile Platform Scope

The active mobile target is Android only. Other Flutter platform folders may exist from the initial scaffold, but they are not part of the current delivery scope.

## Local Development Startup

From PowerShell:

```powershell
cd C:\xampp\htdocs\RabbiTrack
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1
```

This starts PostgreSQL, Redis, Mailpit, runs Laravel migrations, starts the API on port `8000` if needed, and verifies `/api/v1/health`.

Local demo login:

```text
owner@rabbitrack.local
secret-password
```

The startup script keeps this demo account, farm, location, and starter rabbits seeded safely, so it can be run again after restarting the machine.

Android emulator API base URL:

```text
http://10.0.2.2:8000/api/v1
```

Physical Android phone over USB:

```powershell
cd C:\xampp\htdocs\RabbiTrack
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\install-android-phone.ps1
```

The phone build uses:

```text
http://127.0.0.1:8000/api/v1
```

The install script enables `adb reverse tcp:8000 tcp:8000`, so keep the phone connected by USB while testing against the local API. If you unplug or restart the phone, run the install script again or manually run `adb reverse tcp:8000 tcp:8000`.

The USB installer checks `http://127.0.0.1:8000/api/v1/health` before building. If you are intentionally building without the local API running, add `-SkipApiCheck`.

Physical Android phone over Wi-Fi:

```powershell
cd C:\xampp\htdocs\RabbiTrack
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\install-android-wireless.ps1
```

This builds the app with your PC's detected LAN address, for example:

```text
http://192.168.1.128:8000/api/v1
```

After installing, the phone can be unplugged, but it must stay on the same Wi-Fi/network as the PC. If the phone cannot reach the API, open Windows Terminal or PowerShell as Administrator and run:

```powershell
New-NetFirewallRule -DisplayName "RabbiTrack Laravel API 8000" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -Profile Private
```

The wireless installer checks `http://<your-pc-ip>:8000/api/v1/health` before building. If your PC has multiple network adapters, pass the IP manually:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-android-wireless.ps1 -HostIp 192.168.1.128
```

If you need to build without checking the API first, add `-SkipApiCheck`.

Mailpit inbox:

```text
http://127.0.0.1:8025
```
