-- One row per player per gameweek per model version.
select
    id as prediction_id,
    player_id,
    season,
    gameweek,
    predicted_points,
    model_version,
    tier_or_label,
    created_at as predicted_at
from {{ source('raw', 'ml_predictions') }}

-- Keep real seasons only (for example 2025-26). Simulation and test seasons
-- such as SIMSMOKE and 9998-00 are excluded here and stay untouched in raw.
where regexp_contains(season, r'^20[0-9]{2}-[0-9]{2}$')
