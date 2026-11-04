-- One row per fixture: when the app plans to check the match and when it did.
select
    id as poll_schedule_id,
    fixture_id,
    halftime_scheduled as is_halftime_scheduled,
    fulltime_scheduled as is_fulltime_scheduled,
    scheduled_at,
    halftime_polled_at,
    fulltime_polled_at,
    final_polled_at,
    _batch_id,
    _loaded_at
from {{ source('bronze', 'ml_fixture_poll_schedule') }}
