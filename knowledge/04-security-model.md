# 04 Security model

## Postgres role `pitchside_extract`
- Login only, maximum 2 connections.
- SELECT on the 10 approved tables.
- On `public.task_heartbeats`, SELECT on only `task_name`, `last_success_at`, `last_failure_at`.
- Verified: reading `users` and `last_error` is denied.
- The password lives in `~/.pitchside/pg_extract_pw` on the VM (mode 600). It is never in git.
- It reuses nothing from the existing `readonly_user` role.

## Excluded data
- `users` (email, username, password_hash)
- `password_reset_tokens`
- invite codes
- `last_error` column
- `alembic_version`
- all user-linked tables, for now

## GCP access
| Identity | Can do |
|---|---|
| pitchside-extractor | write to the bucket; write to `bronze`; run BigQuery jobs |
| VM default compute account | impersonate pitchside-extractor (no keys) |

## Rules
- No key files anywhere.
- Never commit passwords, tokens or user data.
