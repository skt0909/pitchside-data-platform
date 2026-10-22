-- Model predictions next to the points players actually scored.
with actual as (
    select
        player_id,
        season,
        gameweek,
        sum(total_points) as actual_points
    from {{ ref('fct_player_gameweek') }}
    group by player_id, season, gameweek
)

select
    pr.prediction_id,
    pr.player_id,
    p.player_name,
    p.player_position,
    pr.season,
    pr.gameweek,
    pr.model_version,
    pr.tier_or_label,
    pr.predicted_points,
    a.actual_points,
    abs(pr.predicted_points - a.actual_points) as absolute_error
from {{ ref('stg_ml_predictions') }} as pr
left join {{ ref('dim_players') }} as p
    on pr.player_id = p.player_id
inner join actual as a
    on pr.player_id = a.player_id
    and pr.season = a.season
    and pr.gameweek = a.gameweek
