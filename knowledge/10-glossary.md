# 10 Glossary

- **Parquet**: a compact, column-based file format with types built in. Example: `players.parquet` is much smaller than the same data as CSV.
- **Manifest**: a small file listing what a batch contains (tables, row counts). Written last, so its presence means the batch is complete. Example: Bronze compares its loaded row count with the manifest.
- **Snapshot**: a full copy of a table at one moment. Example: each daily run copies all 670 players.
- **Batch**: one run of the extractor, identified by a `batch_id`.
- **Medallion (bronze/silver/gold)**: layers of data quality. Bronze is raw, silver is cleaned, gold is business-ready.
- **Bronze**: faithful copy of the source. Example: `bronze.players` has the same columns plus `_batch_id`.
- **dbt**: a tool that builds tables from SQL files and tests them.
- **CDC (change data capture)**: tracking row-by-row changes. We do not use it; we take snapshots.
- **Impersonation**: one identity temporarily acting as another, with no key file. Example: the VM account acts as `pitchside-extractor`.
- **Service account**: a non-human GCP identity for programs.
- **Org policy**: a rule set by the organisation. Ours blocks service account keys.
- **Celery / Celery Beat**: Celery runs background tasks; Beat is its scheduler.
- **Heartbeat**: a row recording when a task last succeeded or failed.
- **Gate**: a check that must pass before the extractor runs.
- **REPEATABLE READ**: a database mode where a transaction sees one consistent view of the data.
- **Server-side cursor**: lets the client fetch rows in chunks instead of loading everything into memory.
- **Egress**: data leaving a cloud region, which can cost money.
- **Semantic layer**: shared definitions of metrics so everyone calculates them the same way.
