# 02 VM and scheduling

## The VM
- Name `ps-vps`, Google Compute Engine, zone us-central1-a.
- Machine type e2-micro: about 1 GB RAM plus 1 GB swap. Very small.
- Runs Postgres 18.

## How the app runs
systemd services: `fpl-api`, `fpl-worker`, `fpl-beat`, plus `nginx` and `redis`.
No cron daemon is installed.

## Schedule
The schedule lives in Celery Beat (`Worker/celery_app.py`), all in UTC.

| Task | How often |
|---|---|
| poll_due_fixtures | every 60 s |
| lock_expired_gameweeks | every 5 min |
| carry_forward_selections | every 5 min |
| lock_dream11_contests | every 5 min |
| refresh_active_gameweeks | every 15 min |
| finalize_dream11_contests | every 15 min |
| refresh_fixtures | every 15 min |
| refresh_player_prices | daily 01:30 UTC |

## Heartbeats
Each task writes to `public.task_heartbeats` with `task_name`, `last_success_at`, `last_failure_at` and `last_error`.

## What is NOT running
- There is **no 5:30 AM backfill**. `fpl-backfill.timer` only exists as a template in the app repo and is not installed.
- Predictions are **frozen**: last written 2026-09-22 (gameweeks 5 and 6).
- So the pipeline gates on the Beat heartbeats instead, and flags predictions as frozen.
