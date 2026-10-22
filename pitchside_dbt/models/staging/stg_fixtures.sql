-- One row per fixture.
select
    id as fixture_id,
    fpl_id as fpl_fixture_id,
    season,
    gameweek,
    home_team_id,
    away_team_id,
    kickoff_time,
    home_score,
    away_score,
    finished as is_finished
from {{ source('raw', 'fixtures') }}

-- Keep real seasons only (for example 2025-26). Simulation and test seasons
-- such as SIMSMOKE and 9998-00 are excluded here and stay untouched in raw.
where regexp_contains(season, r'^20[0-9]{2}-[0-9]{2}$')
