-- Players, one row per player per season, with the team name attached.
select
    p.player_id,
    p.fpl_player_id,
    p.season,
    p.player_name,
    p.web_name,
    p.player_position,
    p.team_id,
    t.team_name,
    t.team_short_name,
    p.start_price_millions,
    p.availability_status
from {{ ref('stg_players') }} as p
left join {{ ref('dim_teams') }} as t
    on p.team_id = t.team_id
