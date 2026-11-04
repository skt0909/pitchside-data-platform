# 07 Data dictionary

Row counts are from the extraction on 2026-11-03.

## Ingested (10 tables)
| Table | Rows | Notes |
|---|---|---|
| ml.players | 670 | |
| ml.teams | 20 | |
| ml.fixtures | 380 | |
| ml.player_gw_stats | 5882 | |
| ml.season_stats | 0 | empty for now |
| ml.player_gw_features | 0 | empty for now |
| ml.ml_predictions | 1318 | frozen since 2026-09-22 (gameweeks 5 and 6) |
| ml.fixture_poll_schedule | 344 | |
| public.gameweeks | 4 | |
| public.ruleset_epochs | 1 | |

## Numeric columns
Numeric columns are stored as strings in Bronze. TODO: list the exact numeric columns per table (read them from `information_schema`) and add them here.

## Excluded
`users`, `password_reset_tokens`, invite codes, `last_error`, `alembic_version`, and all user-linked tables. See [04-security-model.md](04-security-model.md).

## Gold: `fct_player_gameweek` additions
- `gameweek_key`: season and gameweek joined with a dash (for example `2026-27-5`). Same as in `dim_gameweeks`.
- `kickoff_time`: kick-off of the player's fixture. Can be empty for postponed fixtures.

## Gold: enforced contracts
`fct_player_gameweek` (27 columns), `dim_players` (11), `dim_teams` (11) and `dim_gameweeks` (10) have enforced dbt contracts in `models/marts/_marts.yml`. The contract fixes the column names and BigQuery types. `price_millions` and `start_price_millions` are FLOAT64, and changing either to NUMERIC would be a breaking change needing a version bump.
