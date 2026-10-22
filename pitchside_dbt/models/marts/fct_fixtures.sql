-- Fixtures with team names and the match result.
select
    f.fixture_id,
    f.season,
    f.gameweek,
    f.kickoff_time,
    f.home_team_id,
    h.team_name as home_team,
    f.away_team_id,
    a.team_name as away_team,
    f.home_score,
    f.away_score,
    f.is_finished,
    case
        when not coalesce(f.is_finished, false) then null
        when f.home_score is null or f.away_score is null then null
        when f.home_score > f.away_score then 'home_win'
        when f.home_score < f.away_score then 'away_win'
        else 'draw'
    end as result
from {{ ref('stg_fixtures') }} as f
left join {{ ref('dim_teams') }} as h
    on f.home_team_id = h.team_id
left join {{ ref('dim_teams') }} as a
    on f.away_team_id = a.team_id
