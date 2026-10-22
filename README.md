# pitchside-data-platform

# Pitchside Data Platform

An analytics pipeline built on the data behind [Pitchside](https://github.com/skt0909/EXP), a Fantasy Premier League app I built (FastAPI, PostgreSQL, XGBoost). It moves the app's data into BigQuery and models it with dbt into tested, documented tables.

## Architecture

```
Pitchside PostgreSQL (local copy)
        │  ingestion/export_and_load.py  (pandas → Parquet → BigQuery)
        ▼
BigQuery  raw.*            5 tables, loaded as-is
        │  dbt
        ▼
BigQuery  analytics.stg_*  staging views: renamed, typed, simulated seasons filtered out
        │  dbt
        ▼
BigQuery  analytics.*      marts: dimensions, facts and a rolling-form table
```

![Lineage graph](docs/lineage.png)

## Models

| Layer | Model | What it holds |
| --- | --- | --- |
| Staging | `stg_teams`, `stg_players`, `stg_fixtures`, `stg_player_gw_stats`, `stg_ml_predictions` | Cleaned one-to-one views of the raw tables |
| Marts | `dim_teams`, `dim_players` | Team and player dimensions |
| Marts | `fct_fixtures` | One row per fixture with a home_win / away_win / draw result |
| Marts | `fct_player_gameweek` | One row per player per fixture, with opponent and stats |
| Marts | `player_form` | Points per gameweek and a rolling 3-gameweek average |
| Marts | `fct_prediction_vs_actual` | Model predictions against actual points, with absolute error |

## Data quality

34 dbt tests: `unique`, `not_null`, `relationships` and `accepted_values`, plus one custom test that warns when a gameweek has fewer than 50 stat rows. That test deliberately flags one stray gameweek 38 row in 2026-27. The marts exclude gameweeks below that threshold, because otherwise the rolling form window would average gameweeks that are 33 weeks apart.

## Data coverage

This is a sample, not a full season: 2025-26 gameweeks 1 to 4 and 2026-27 gameweeks 1 to 5 (about 5.8k player-gameweek rows and 1.3k predictions). Simulated seasons that exist in the app's database are filtered out in staging. The source was a local copy of the database, never production.

## Run it

```
pip install -r requirements.txt
# .env needs SRC_DB_URL (a Postgres URL) and GCP_PROJECT
gcloud auth application-default login
python ingestion/export_and_load.py
cd pitchside_dbt
dbt run
dbt test
dbt docs generate && dbt docs serve
```

Built on the BigQuery sandbox free tier.
