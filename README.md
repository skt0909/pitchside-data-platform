# Pitchside Data Platform

An analytics-engineering project built on the data behind [Pitchside](https://github.com/skt0909/EXP), a full-stack fantasy football app (FastAPI, PostgreSQL, React, XGBoost). It takes the app's operational data, loads it into a cloud warehouse, models it with dbt, and tests it.

> **Status:** two tracks are built. The BigQuery + dbt analytics layer is complete and tested, and the PySpark / Databricks layer (raw, cleaned and feature tables) is built and validated against dbt. Next steps are in the [Roadmap](#roadmap).

## Architecture

```mermaid
flowchart LR
    A[(Pitchside PostgreSQL<br/>local, non-production copy)] --> B[export_and_load.py<br/>Parquet export + load]
    B --> C[(BigQuery<br/>raw dataset)]
    C --> D[dbt staging<br/>5 views]
    D --> E[dbt marts<br/>6 tables]
    E --> F[Analysis / reporting]
    D -. tests .-> T{{dbt tests<br/>34 checks}}
    E -. tests .-> T
    B --> G[(Databricks<br/>Parquet volume)]
    G --> H[PySpark raw<br/>Delta tables]
    H --> I[PySpark cleaned<br/>Delta tables]
    I --> J[PySpark features<br/>model-ready table]
```

Two tracks from the same source: **dbt on BigQuery** produces tables for reporting and analysis (marts), while **PySpark on Databricks** produces a feature table for modelling.

![dbt lineage graph](docs/lineage.png)

## What it does

| Layer | Built with | Contents |
| --- | --- | --- |
| Ingestion | Python, pandas, `google-cloud-bigquery` | Reads 5 tables from PostgreSQL, writes Parquet, loads to BigQuery `raw` with a row-count check (rows read = rows loaded) |
| Staging | dbt (views) | `stg_teams`, `stg_players`, `stg_fixtures`, `stg_player_gw_stats`, `stg_ml_predictions`: renamed columns, unit fixes (prices in millions), simulated seasons filtered out |
| Marts | dbt (tables) | `dim_teams`, `dim_players`, `fct_fixtures`, `fct_player_gameweek`, `player_form`, `fct_prediction_vs_actual` |
| Quality | dbt tests | `unique`, `not_null`, `relationships`, `accepted_values`, plus a custom test that warns on sparse gameweeks |
| Raw (Databricks) | PySpark, Delta | `raw_*` tables: the five Parquet files loaded unchanged, with a `_loaded_at` audit column; row counts checked against the export |
| Cleaned (Databricks) | PySpark, Delta | `cleaned_*` tables: simulated seasons removed, one row per key, sparse gameweeks excluded (same rules as dbt; 5,809 stat rows in both) |
| Features (Databricks) | PySpark, Delta | `features_player_gameweek`: one row per player per gameweek with rolling form, minutes trend, xG/xA, opponent strength and the points label |

### Feature layer

`features_player_gameweek` has 5,809 rows, one per player per gameweek. Rolling features (`form_3`, `form_5`, `minutes_3`, `xg_3`, `xa_3`) use **only earlier gameweeks**, so a row never sees its own result. This is verified: every first gameweek has an empty `form_3`. Opponent strength is standardised within each season (`*_z` columns), because the two seasons use different scales. `has_complete_inputs` marks rows that are ready for modelling.

### Marts

- **`fct_player_gameweek`**: one row per player per fixture, with opponent and match stats.
- **`player_form`**: points per player per gameweek and a rolling 3-gameweek average (window function). Double gameweeks are summed first so each gameweek counts once.
- **`fct_fixtures`**: fixtures with a derived result (`home_win`, `away_win`, `draw`).
- **`fct_prediction_vs_actual`**: model predictions against actual points, with absolute error, for evaluating the Pitchside model.
- **`dim_teams`, `dim_players`**: conformed dimensions.

## Data quality

Tests: 34 in total, 33 pass and 1 intentional warning.

- Staging filters seasons to the pattern `YYYY-YY`. This removes simulation seasons that had leaked into the local database, while the raw layer is left untouched.
- `fct_player_gameweek` excludes gameweeks with fewer than 50 stat rows. This was found in the data: 2026-27 gameweek 38 holds 2 stray rows, which would otherwise be averaged into the rolling form of players as if it followed gameweek 5.
- `assert_gameweek_has_enough_rows` reports such gameweeks on every run with `severity: warn`, so the issue stays visible instead of being silently hidden.

## Data coverage

This is a **sample**, not a full season. It holds gameweeks 1 to 4 of 2025-26 and gameweeks 1 to 5 of 2026-27 from a local, non-production copy of the Pitchside database. Totals (for example top scorers) reflect those gameweeks only.

2026-27 is the **live** season, so its inputs are partially populated and fill in as gameweeks are ingested: some prices and expected-goals values are still missing, and opponent strength is a different measure from 2025-26 (a 2-to-5 tier rather than FPL's rating), with no defence-specific value. In the feature layer, missing prices are `NULL` (not zero), strength is standardised within season, and `has_complete_inputs` is false for rows that lack inputs. As a result, only 2025-26 rows are currently marked complete (2,107 rows). The pipeline overwrites its tables on each run, so it can simply be re-run as more data arrives.

## Stack

Python 3 · pandas · PostgreSQL · Google BigQuery (sandbox) · dbt Core 1.12 + `dbt-bigquery` · PySpark · Databricks Free Edition · Delta Lake · Parquet

## Run it

```bash
python -m venv venv
venv\Scripts\activate            # Windows
pip install -r requirements.txt

# .env (not committed)
# SRC_DB_URL=postgresql+psycopg2://user:password@host:5432/dbname
# GCP_PROJECT=<your-gcp-project-id>

gcloud auth application-default login

python ingestion/export_and_load.py      # PostgreSQL -> Parquet -> BigQuery raw

cd pitchside_dbt
dbt run
dbt test
dbt docs generate && dbt docs serve
```

**Databricks track:** upload the Parquet files from `exports/` to a Unity Catalog volume at `/Volumes/workspace/pitchside/landing/`, then run the notebooks in `databricks/` in order: `01_raw`, `02_cleaned`, `03_features`.

The source database is a local copy. The scripts never need, and were never pointed at, the production database.

## Roadmap

- [x] PySpark on Databricks Free Edition: raw, cleaned and feature layers
- [ ] Extend the feature layer towards the full Pitchside feature set
- [ ] Scheduled runs and CI for `dbt build`
- [ ] Load more gameweeks for fuller coverage
- [ ] Model retraining (MLOps) on the feature layer

## Related

- [Pitchside](https://github.com/skt0909/EXP): the application this data comes from.