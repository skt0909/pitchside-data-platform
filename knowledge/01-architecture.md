# 01 Architecture

Data moves in one direction, one hop at a time.

```mermaid
flowchart LR
  A[Football API] --> B[Celery tasks in the app]
  B --> C[(Postgres on VM)]
  C --> D[extractor.py<br/>daily 06:00 UTC]
  D --> E[GCS Parquet + manifest]
  E --> F[bronze_loader.py]
  F --> G[(BigQuery bronze)]
  G --> H[dbt silver]
  H --> I[dbt gold]
  I --> J[Semantic layer]
  J --> K[Data products]
  K --> L[Marketplace]
```

## The hops

1. **Football API -> Celery tasks.** The existing app calls the football API on a schedule using Celery tasks.
2. **Celery tasks -> Postgres.** The tasks save fixtures, players, stats and predictions into Postgres on the VM.
3. **Postgres -> extractor.py.** Every day at 06:00 UTC the extractor reads Postgres. It never calls the football API.
4. **extractor.py -> GCS.** It writes one Parquet file per table, plus a manifest, into the bucket.
5. **GCS -> bronze_loader.py -> BigQuery bronze.** The loader copies the Parquet files into BigQuery without changing the data.
6. **Bronze -> dbt silver.** dbt cleans and standardises.
7. **Silver -> dbt gold.** dbt builds business-ready tables.
8. **Gold -> semantic layer.** Shared definitions of metrics.
9. **Semantic layer -> data products -> marketplace.** What consumers finally use.

dbt and the marketplace run off the VM because the VM has very little memory.

## dbt project files (silver, gold, semantic layer)
- `pitchside_dbt/models/staging/`: Silver views in dataset `silver` (`_sources.yml`, `_staging.yml`, ten `stg_*` models).
- `pitchside_dbt/models/marts/`: Gold tables in dataset `gold`, including `dim_gameweeks`.
- `models/marts/_semantic.yml`: the semantic layer. It defines four semantic models (player_gameweek, players, teams, gameweeks) and six metrics.
- `models/marts/metricflow_time_spine.sql`: one row per day. The semantic layer needs it. It is plumbing, not a data product table.
- `macros/generate_schema_name.sql`: makes datasets exactly `silver` and `gold`.
- `tests/generic/`: custom tests `accepted_range` and `matches_pattern`.
