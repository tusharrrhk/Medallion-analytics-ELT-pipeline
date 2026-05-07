-- Fact table for Airbnb bookings - Star Schema
{{ config(materialized='table') }}

select
    -- Foreign Keys
    b.booking_id,
    l.listing_id,
    l.host_id,

    -- Measures
    b.total_booking_amount as booking_amount,
    b.cleaning_fee,
    b.service_fee,
    b.total_booking_amount + coalesce(b.cleaning_fee, 0) + coalesce(b.service_fee, 0) as total_revenue,

    -- Degenerate Dimensions (intrinsic to the booking transaction)
    b.booking_date,
    b.booking_status,
    b.booking_created_at

from {{ ref('dim_bookings') }} b
left join {{ ref('dim_listings') }} l on b.listing_id = l.listing_id
left join {{ ref('dim_hosts') }} h on l.host_id = h.host_id

