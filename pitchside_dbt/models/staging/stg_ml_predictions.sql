-- One row per player per gameweek per model version.
-- FROZEN: only gameweeks 5 and 6 (xgboost_v1) exist, last written 2026-09-22.
select
    id as prediction_id,
    player_id,
    season,
    gameweek,
    safe_cast(predicted_points as numeric) as predicted_points,
    model_version,
    tier_or_label,
    created_at as predicted_at,
    _batch_id,
    _loaded_at
from {{ source('bronze', 'ml_ml_predictions') }}
