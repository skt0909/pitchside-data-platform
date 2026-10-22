-- One row per player per fixture: who played, against whom, and what they scored.
-- Gameweeks with fewer than 50 stat rows are excluded: they are stray or partial
-- data (e.g. 2026-27 GW38 has 2 rows) and would distort totals and rolling form.
with valid_gameweeks as (
    select season, gameweek
    from {{ ref('stg_player_gw_stats') }}
    group by season, gameweek
    having count(*) >= 50
)

select
    s.player_gw_stat_id,
    s.player_id,
    p.player_name,
    p.player_position,
    p.team_id,
    p.team_name,
    s.season,
    s.gameweek,
    s.fixture_id,
    s.was_home,
    case
        when s.was_home is null then null
        when s.was_home then fx.away_team
        else fx.home_team
    end as opponent,
    s.minutes,
    s.goals_scored,
    s.assists,
    s.clean_sheets,
    s.goals_conceded,
    s.saves,
    s.bonus,
    s.bps,
    s.yellow_cards,
    s.red_cards,
    s.expected_goals,
    s.expected_assists,
    s.price_millions,
    s.total_points
from {{ ref('stg_player_gw_stats') }} as s
inner join valid_gameweeks as v
    on s.season = v.season
    and s.gameweek = v.gameweek
left join {{ ref('dim_players') }} as p
    on s.player_id = p.player_id
left join {{ ref('fct_fixtures') }} as fx
    on s.fixture_id = fx.fixture_id