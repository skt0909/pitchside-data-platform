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
    strength_defence_away,
    created_at,
    updated_at,
    _batch_id,
    _loaded_at
from {{ source('bronze', 'ml_teams') }}
