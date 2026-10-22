-- One row per player per season. FPL prices are stored in tenths of a million,
-- so 55 becomes 5.5.
select
    id as player_id,
    fpl_id as fpl_player_id,
    season,
    fpl_name as player_name,
    web_name,
    position as player_position,
    team_id,
    cost_start / 10.0 as start_price_millions,
    status as availability_status
from {{ source('raw', 'players') }}

-- Keep real seasons only (for example 2025-26). Simulation and test seasons
-- such as SIMSMOKE and 9998-00 are excluded here and stay untouched in raw.
where regexp_contains(season, r'^20[0-9]{2}-[0-9]{2}$')
