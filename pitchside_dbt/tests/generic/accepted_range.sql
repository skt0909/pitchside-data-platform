{% test accepted_range(model, column_name, min_value, max_value) %}
-- Returns rows whose value falls outside the range. NULLs are not flagged
-- (a comparison with NULL is never true), so missing values stay missing.
select *
from {{ model }}
where {{ column_name }} < {{ min_value }}
   or {{ column_name }} > {{ max_value }}
{% endtest %}
