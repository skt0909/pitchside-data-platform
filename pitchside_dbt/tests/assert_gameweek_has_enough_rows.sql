{{ config(severity='warn') }}

select season, gameweek, count(*) as stat_rows
from {{ ref('stg_player_gw_stats') }}
group by season, gameweek
having count(*) < 50