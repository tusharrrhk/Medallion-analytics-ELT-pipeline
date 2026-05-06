{# select * from {{ source('staging', 'listings') }} #}

--------------------------------------------------------------

{# {% set incremental_flag = 1 %}
{% set incremental_col = 'created_at' %}

select *
from {{ source('staging', 'bookings') }}

{% if incremental_flag == 1 %}
    where {{ incremental_col }} > (select coalesce(max({{ incremental_col }}), '1900-01-01') from {{ ref('bronze_listings') }})
{% endif %} #}

--------------------------------------------------------------

{{ config(materialized='incremental') }}

select *
from {{ source('staging', 'listings') }}

{% if is_incremental() %}
    where created_at > (select coalesce(max(created_at), '1900-01-01') from {{ this }})
{% endif %}