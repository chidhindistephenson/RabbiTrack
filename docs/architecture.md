# Architecture Baseline

RabbiTrack starts as a modular monolith.

## Backend

The Laravel application is the authoritative system of record. It owns authentication, authorization, validation, business rules, task generation, reporting, audit history, and synchronization conflict outcomes.

Protected endpoints are served under `/api/v1`.

## Mobile

The Flutter application targets Android only for the current delivery scope. It is offline-first for critical field workflows. It writes changes locally before showing a successful save, then synchronizes through a durable outbox when connectivity returns.

## Data

PostgreSQL stores authoritative relational records. SQLite stores each device's working set and pending changes. Redis supports queues, cache, and background work.

## Local Development

Docker Compose provides PostgreSQL, Redis, and Mailpit. Laravel can run through `php artisan serve`, and Flutter can run through `flutter run`.
