{{ config(materialized='table') }}

select
    booking_id,
    listing_id,
    host_id,
    booking_date,
    total_booking_amount,
    cleaning_fee,
    service_fee,
    booking_status,
    created_at as booking_created_at,
    -- Add any additional dimension attributes
    case
        when booking_status = 'completed' then 'Successful'
        when booking_status = 'cancelled' then 'Cancelled'
        else 'Pending/Other'
    end as booking_outcome,
    date_part('month', booking_date) as booking_month,
    date_part('year', booking_date) as booking_year
from {{ ref('silver_booking') }}