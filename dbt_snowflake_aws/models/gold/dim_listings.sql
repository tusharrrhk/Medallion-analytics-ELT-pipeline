{{ config(materialized='table') }}

select
    listing_id,
    host_id,
    property_type,
    room_type,
    city,
    country,
    bedrooms,
    bathrooms,
    price_per_night,
    price_category,
    created_at as listing_created_at,
    -- Add any additional dimension attributes
    case
        when bedrooms >= 3 then 'Large'
        when bedrooms = 2 then 'Medium'
        else 'Small'
    end as size_category
from {{ ref('silver_listing') }}