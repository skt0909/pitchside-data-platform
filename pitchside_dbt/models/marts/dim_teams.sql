-- Teams, one row per team per season.
select
    team_id,
    fpl_team_id,
    season,
    team_name,
    team_short_name,
    strength_overall_home,
    strength_overall_away,
    strength_attack_home,
    strength_attack_away,
    strength_defence_home,
    strength_defence_away
from {{ ref('stg_teams') }}
