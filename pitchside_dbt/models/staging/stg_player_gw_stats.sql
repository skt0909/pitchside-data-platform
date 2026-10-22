-- One row per player per fixture, with prices converted to millions.
select
    id as player_gw_stat_id,
    player_id,
    fixture_id,
    season,
    gameweek,
    is_live,
    minutes,
    goals_scored,
    assists,
    clean_sheets,
    goals_conceded,
    saves,
    bonus,
    bps,
    yellow_cards,
    red_cards,
    own_goals,
    penalties_saved,
    penalties_missed,
    ict_index,
    influence,
    creativity,
    threat,
    expected_goals,
    expected_assists,
    expected_goal_involvements,
    value / 10.0 as price_millions,
    selected,
    transfers_in,
    transfers_out,
    transfers_balance,
    was_home,
    team_h_score,
    team_a_score,
    total_points
from {{ source('raw', 'player_gw_stats') }}

-- Keep real seasons only (for example 2025-26). Simulation and test seasons
-- such as SIMSMOKE and 9998-00 are excluded here and stay untouched in raw.
where regexp_contains(season, r'^20[0-9]{2}-[0-9]{2}$')
