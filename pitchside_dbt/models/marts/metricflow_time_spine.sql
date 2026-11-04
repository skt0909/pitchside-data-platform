-- One row per calendar day. MetricFlow needs this table to line metrics up by date.
select day as date_day
from unnest(generate_date_array('2025-01-01', '2030-12-31', interval 1 day)) as day
