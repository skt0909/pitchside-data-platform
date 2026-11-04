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
    finished as is_finished,
    started as is_started,
    finished_provisional as is_finished_provisional,
    minutes as minutes_played,
    created_at,
    updated_at,
    _batch_id,
    _loaded_at
from {{ source('bronze', 'ml_fixtures') }}
