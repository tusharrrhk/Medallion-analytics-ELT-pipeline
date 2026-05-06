{# select * from {{ source('staging', 'bookings') }} #}

{{ config(materialized='incremental') }}

select *
from {{ source('staging', 'bookings') }}

{% if is_incremental() %}
    where created_at > (select coalesce(max(created_at), '1900-01-01') from {{ this }})
{% endif %}

    {# where {{ incremental_col }} > (select coalesce(max({{ incremental_col }}), '1900-01-01') from {{ ref('bronze_bookings') }}) #}
