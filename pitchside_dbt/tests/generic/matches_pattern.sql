{% test matches_pattern(model, column_name, pattern) %}
-- Returns rows whose value does not match the regular expression (NULLs count as
-- not matching). Used to catch season labels that are not in the form 2026-27.
select *
from {{ model }}
where not coalesce(regexp_contains(cast({{ column_name }} as string), r'{{ pattern }}'), false)
{% endtest %}
