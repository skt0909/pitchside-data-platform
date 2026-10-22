-- Points per player per gameweek, plus the average of the last three gameweeks.
-- Double gameweeks are summed first so each gameweek counts once.
with per_gameweek as (
    select
        player_id,
        player_name,
        player_position,
        season,
        gameweek,
        sum(total_points) as points,
        sum(minutes) as minutes
    from {{ ref('fct_player_gameweek') }}
    group by player_id, player_name, player_position, season, gameweek
)

select
    player_id,
    player_name,
    player_position,
    season,
    gameweek,
    points,
    minutes,
    avg(points) over (
        partition by player_id, season
        order by gameweek
        rows between 2 preceding and current row
    ) as points_rolling_3
from per_gameweek
