-- ===========================================
-- BOOKING TRENDS EXPLORATION
-- ===========================================

-- Monthly booking volume and revenue trends
SELECT
    DATE_TRUNC('month', booking_date) as booking_month,
    COUNT(*) as total_bookings,
    SUM(total_booking_amount) as total_revenue,
    AVG(total_booking_amount) as avg_booking_value,
    COUNT(DISTINCT listing_id) as unique_listings_booked,
    COUNT(DISTINCT host_id) as unique_hosts_with_bookings
FROM {{ ref('obt') }}
GROUP BY DATE_TRUNC('month', booking_date)
ORDER BY booking_month DESC;

-- Booking status distribution over time
SELECT
    DATE_TRUNC('month', booking_date) as booking_month,
    booking_status,
    COUNT(*) as booking_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY DATE_TRUNC('month', booking_date)), 2) as status_percentage
FROM {{ ref('obt') }}
GROUP BY DATE_TRUNC('month', booking_date), booking_status
ORDER BY booking_month DESC, booking_count DESC;

-- Seasonal booking patterns (by month)
SELECT
    MONTH(booking_date) as booking_month,
    MONTHNAME(booking_date) as month_name,
    COUNT(*) as total_bookings,
    SUM(total_booking_amount) as total_revenue,
    AVG(total_booking_amount) as avg_booking_value,
    ROUND(AVG(total_booking_amount), 2) as avg_booking_value_rounded
FROM {{ ref('obt') }}
GROUP BY MONTH(booking_date), MONTHNAME(booking_date)
ORDER BY booking_month;

-- Weekend vs weekday booking patterns
SELECT
    CASE
        WHEN DAYOFWEEK(booking_date) IN (1,7) THEN 'Weekend'
        ELSE 'Weekday'
    END as day_type,
    COUNT(*) as booking_count,
    SUM(total_booking_amount) as total_revenue,
    AVG(total_booking_amount) as avg_booking_value
FROM {{ ref('obt') }}
GROUP BY
    CASE
        WHEN DAYOFWEEK(booking_date) IN (1,7) THEN 'Weekend'
        ELSE 'Weekday'
    END;