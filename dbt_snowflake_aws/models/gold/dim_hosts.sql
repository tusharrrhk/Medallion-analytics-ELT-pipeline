{{ config(materialized='table') }}

select
    host_id,
    host_name,
    host_since,
    is_superhost,
    response_rate,
    response_rate_category,
    created_at as host_created_at,
    -- Add any additional dimension attributes
    datediff('year', host_since, current_date()) as years_as_host,
    case
        when datediff('year', host_since, current_date()) >= 5 then 'Veteran'
        when datediff('year', host_since, current_date()) >= 2 then 'Experienced'
        else 'New'
    end as host_experience_level
from {{ ref('silver_hosts') }}