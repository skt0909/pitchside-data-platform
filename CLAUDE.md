# Pitchside data platform: brief for Claude

Read `knowledge/README.md` first. It indexes everything about the architecture, GCP setup, security model, extractor, Bronze layer and decisions.

## Rules

1. **No key files.** Never create, read, print or commit service account keys, passwords, tokens or `.env` contents. The VM impersonates a service account instead.
2. **Never touch excluded tables.** `users`, `password_reset_tokens`, invite codes, `alembic_version`, `last_error` and all user-linked tables are off limits. See `knowledge/04-security-model.md`.
3. **Stop between stages.** Finish one stage, report, and wait for approval before starting the next.
4. **Explain changes simply.** Say what changed and why in plain words, for a learner.
5. **Update the knowledge folder** when a decision, command or fact changes.

## One-line architecture

Football API -> Celery tasks -> Postgres on VM -> extractor.py -> GCS Parquet + manifest -> bronze_loader.py -> BigQuery bronze -> dbt silver -> dbt gold -> semantic layer -> data products -> marketplace.
