-- Fact table for Airbnb bookings - Star Schema
{{ config(materialized='table') }}

select
    -- Foreign Keys
    b.booking_id,
    b.listing_id,
    b.host_id,

    -- Measures
    b.total_booking_amount as booking_amount,
    b.cleaning_fee,
    b.service_fee,
    b.total_booking_amount + coalesce(b.cleaning_fee, 0) + coalesce(b.service_fee, 0) as total_revenue,

    -- Degenerate Dimensions (from fact)
    b.booking_date,
    b.booking_status,
    b.created_at as booking_created_at,

    -- Dimension Attributes (denormalized for analytics)
    l.property_type,
    l.room_type,
    l.city,
    l.country,
    l.bedrooms,
    l.bathrooms,
    l.price_per_night,
    l.price_category,
    l.size_category,

    h.host_name,
    h.is_superhost,
    h.response_rate,
    h.response_rate_category,
    h.years_as_host,
    h.host_experience_level

from {{ ref('dim_bookings') }} b
left join {{ ref('dim_listings') }} l on b.listing_id = l.listing_id
left join {{ ref('dim_hosts') }} h on b.host_id = h.host_id

