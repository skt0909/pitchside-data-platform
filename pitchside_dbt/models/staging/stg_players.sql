-- One row per player per season. FPL prices are stored in tenths of a million,
-- so 55 becomes 5.5.
select
    id as player_id,
    fpl_id as fpl_player_id,
    season,
    fpl_name as player_name,
    web_name,
    fbref_name,
    position as player_position,
    position_encoded,
    team_id,
    cost_start / 10.0 as start_price_millions,
    now_cost / 10.0 as current_price_millions,
    status as availability_status,
    created_at,
    updated_at,
    _batch_id,
    _loaded_at
from {{ source('bronze', 'ml_players') }}
