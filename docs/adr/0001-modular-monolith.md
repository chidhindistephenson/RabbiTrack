# ADR 0001: Start With A Modular Monolith

## Status

Accepted

## Context

RabbiTrack needs a reliable first production release with strong domain rules around breeding, litter, health, tasks, offline synchronization, reporting, and auditability.

## Decision

The backend will start as one Laravel application organized into clear domain modules rather than separate microservices.

## Consequences

- Deployment and local development remain simpler during MVP delivery.
- Cross-domain transactions are easier to keep consistent.
- Code boundaries still need to be explicit so future extraction remains possible.

