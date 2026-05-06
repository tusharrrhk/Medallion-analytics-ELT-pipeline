{% macro tag(column) %}

    case
        when {{ column }} < 100 then 'budget'
        when {{ column }} < 200 then 'mid-range'
        else 'premium'
    end

{% endmacro %}