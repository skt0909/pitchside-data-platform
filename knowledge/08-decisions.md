# 08 Decision log

| Decision | Reason | Trade-off |
|---|---|---|
| Full daily snapshots instead of CDC | Simple, tables are small | Repeats unchanged rows; no row-level change history |
| Keyless impersonation instead of key files | Org policy blocks keys; keys leak | Needs wider VM scope (`cloud-platform`) |
| us-central1 bucket, US datasets | Free tier, no egress charges | Locked to one region |
| Numeric as string in Bronze | Avoids precision and type drift | Silver must cast |
| Predictions frozen | Backfill is not installed | Prediction data is stale |
| User-linked tables deferred | Privacy; need a proper design first | Less data for now |
| dbt and marketplace run off the VM | VM has about 1 GB RAM | Needs another place to run them |
| Semantic layer in the older YAML layout, separate `_semantic.yml` | dbt 1.12.6 still parses it (checked), and it keeps semantic models out of `_marts.yml`. The newer layout nests them inside each model entry. | The docs prefer the newer layout, so the older one may be removed in a later dbt version |
| Add `metricflow_time_spine` (one row per day, 2025-2030) | dbt refuses to parse semantic models without a time spine | One extra gold table; it is plumbing, kept out of any data product contract |
| Add `kickoff_time` and `gameweek_key` to `fct_player_gameweek` | Measures need a time dimension, and the key links facts to `dim_gameweeks` | `kickoff_time` can be empty for postponed fixtures |
| Pin `dbt-core==1.12.6` and `dbt-bigquery==1.12.1` | Semantic layer behaviour changed across 1.x versions; the project was checked on these | Upgrades are manual |
| Install `dbt-metricflow` (free, open source) in the local venv | Needed to query metrics locally with `mf`; defining and validating metrics does not need it. Installed and working (`mf` commands ran). | Pinned at `dbt-metricflow==0.15.0` in `requirements-dbt.txt` (it installs `metricflow` 0.213.0 as a dependency); upgrades are manual |
| Enforce dbt model contracts on `fct_player_gameweek`, `dim_players`, `dim_teams` and `dim_gameweeks` | The contract fixes the columns and their BigQuery types, so a missing, extra or retyped column fails the build instead of silently reaching consumers. Types were checked against the built gold tables on 2026-11-04. | Changing `price_millions` or `start_price_millions` (FLOAT64) to NUMERIC, or any column or type change, is a breaking change and needs a data product version bump. Not enforced on `fct_fixtures`, `player_form`, `fct_prediction_vs_actual` or `metricflow_time_spine`. |

### Semantic layer: free versus paid (checked against the dbt docs, 2026-11)
- **Free:** defining semantic models and metrics, and `dbt parse` (writes `target/semantic_manifest.json`). MetricFlow itself (`dbt-metricflow`, the `mf` commands) is open source and runs on dbt Core.
- **Paid (dbt platform Starter, Enterprise or Enterprise+):** the Semantic Layer API (GraphQL and JDBC), BI tool integrations, and the `dbt sl` commands.
- We stay on the free side: metrics are queried with `mf`, from `dbt-metricflow` installed in the local venv.

### dbt-state was installed by mistake and removed (2026-11-04)
- `dbt-state` 2.62.6, a build-cache plugin with a trial ending 2026-11-20, was installed in the venv without being asked for.
- No package in the project required it.
- It was uninstalled on 2026-11-04. The build passes without it.
- Fresh installs from `requirements-dbt.txt` do not include it.
- If "State adapter" lines ever reappear in dbt output, check for it with `pip show dbt-state`.
