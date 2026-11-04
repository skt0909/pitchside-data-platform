-- Every (season, gameweek) in fct_player_gameweek must exist in dim_gameweeks.
-- dbt's built-in relationships test checks one column only, so this compares two.
select distinct f.season, f.gameweek
from {{ ref('fct_player_gameweek') }} as f
left join {{ ref('dim_gameweeks') }} as d
    on f.season = d.season
    and f.gameweek = d.gameweek
where d.gameweek_key is null
