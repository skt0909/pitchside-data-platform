-- One row per scored gameweek. The source has no id column, so gameweek_key
-- (season + gameweek, for example 2026-27-5) is built here to give it a single-column key.
select
    concat(season, '-', cast(gameweek as string)) as gameweek_key,
    season,
    gameweek,
    scored_at,
    _batch_id,
    _loaded_at
from {{ source('bronze', 'public_gameweeks') }}
