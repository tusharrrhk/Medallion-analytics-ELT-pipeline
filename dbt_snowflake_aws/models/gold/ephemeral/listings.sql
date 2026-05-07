{{
    config(
        materialized='ephemeral'
    )
}}

with listings as 
(
    select
        listing_id,
        property_type,
        city,
        country,
        price_category,
        listing_created_at
    from {{ ref('obt') }}
)

select * from listings

