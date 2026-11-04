-- One row per scoring-rules version. The source has no id column, so
-- ruleset_epoch_key (season + rules_version) is built here as the key.
select
    concat(season, '-v', cast(rules_version as string)) as ruleset_epoch_key,
    season,
    rules_version,
    first_gameweek,
    created_at,
    _batch_id,
    _loaded_at
from {{ source('bronze', 'public_ruleset_epochs') }}
