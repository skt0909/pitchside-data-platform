-- One row per team per season, with clearer column names.
select
    id as team_id,
    fpl_id as fpl_team_id,
    season,
    name as team_name,
    short_name as team_short_name,
    strength_overall_home,
    strength_overall_away,
    strength_attack_home,
    strength_attack_away,
    strength_defence_home,
    strength_defence_away
from {{ source('raw', 'teams') }}

-- Keep real seasons only (for example 2025-26). Simulation and test seasons
-- such as SIMSMOKE and 9998-00 are excluded here and stay untouched in raw.
where regexp_contains(season, r'^20[0-9]{2}-[0-9]{2}$')
