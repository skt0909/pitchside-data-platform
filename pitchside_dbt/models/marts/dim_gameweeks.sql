-- One row per season and gameweek.
-- The list of gameweeks comes from the fixtures, not from stg_gameweeks, because
-- stg_gameweeks only has the gameweeks that Pitchside has scored. Gameweeks that exist
-- but are not scored yet still get a row, with scored_at empty.
with gameweek_spine as (
    select
        season,
        gameweek,
        min(kickoff_time) as gameweek_start,
        max(kickoff_time) as gameweek_end,
        count(*) as fixture_count,
        -- True only when there is at least one fixture and every one is finished.
        -- A fixture with an empty is_finished counts as not finished.
        count(*) > 0 and logical_and(coalesce(is_finished, false)) as is_finished
    from {{ ref('stg_fixtures') }}
    where gameweek is not null
    group by season, gameweek
),

-- A rules version applies from its first_gameweek until a later version starts.
-- For each gameweek, pick the version with the latest first_gameweek that is not
-- after it.
rules_ranked as (
    select
        g.season,
        g.gameweek,
        r.rules_version,
        row_number() over (
            partition by g.season, g.gameweek
            order by r.first_gameweek desc
        ) as rule_rank
    from gameweek_spine as g
    left join {{ ref('stg_ruleset_epochs') }} as r
        on g.season = r.season
        and r.first_gameweek <= g.gameweek
)

select
    concat(g.season, '-', cast(g.gameweek as string)) as gameweek_key,
    g.season,
    g.gameweek,
    r.rules_version,
    g.gameweek_start,
    g.gameweek_end,
    g.fixture_count,
    g.is_finished,
    s.scored_at,
    s.scored_at is not null as is_scored
from gameweek_spine as g
left join rules_ranked as r
    on g.season = r.season
    and g.gameweek = r.gameweek
    and r.rule_rank = 1
left join {{ ref('stg_gameweeks') }} as s
    on g.season = s.season
    and g.gameweek = s.gameweek
