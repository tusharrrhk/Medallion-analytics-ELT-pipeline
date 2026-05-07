-- ===========================================
-- HOST PERFORMANCE ANALYSIS
-- ===========================================

-- Top performing hosts by revenue
SELECT
    h.host_id,
    h.host_name,
    COUNT(b.booking_id) as total_bookings,
    SUM(b.total_booking_amount) as total_revenue,
    AVG(b.total_booking_amount) as avg_booking_value,
    COUNT(DISTINCT b.listing_id) as unique_listings,
    ROUND(h.response_rate * 100, 1) as response_rate_percent,
    CASE
        WHEN h.is_superhost THEN 'Superhost'
        ELSE 'Regular Host'
    END as host_status
FROM {{ ref('silver_hosts') }} h
LEFT JOIN {{ ref('obt') }} b ON h.host_id = b.host_id
GROUP BY h.host_id, h.host_name, h.response_rate, h.is_superhost
ORDER BY total_revenue DESC
LIMIT 20;

-- Host performance by response rate categories
SELECT
    CASE
        WHEN response_rate >= 0.95 THEN 'Excellent (95%+)'
        WHEN response_rate >= 0.90 THEN 'Very Good (90-94%)'
        WHEN response_rate >= 0.80 THEN 'Good (80-89%)'
        WHEN response_rate >= 0.70 THEN 'Fair (70-79%)'
        ELSE 'Poor (<70%)'
    END as response_category,
    COUNT(*) as host_count,
    AVG(total_bookings) as avg_bookings_per_host,
    AVG(total_revenue) as avg_revenue_per_host,
    SUM(total_bookings) as total_bookings_in_category,
    SUM(total_revenue) as total_revenue_in_category
FROM (
    SELECT
        h.host_id,
        h.response_rate,
        COUNT(b.booking_id) as total_bookings,
        COALESCE(SUM(b.total_booking_amount), 0) as total_revenue
    FROM {{ ref('silver_hosts') }} h
    LEFT JOIN {{ ref('obt') }} b ON h.host_id = b.host_id
    GROUP BY h.host_id, h.response_rate
) host_performance
GROUP BY
    CASE
        WHEN response_rate >= 0.95 THEN 'Excellent (95%+)'
        WHEN response_rate >= 0.90 THEN 'Very Good (90-94%)'
        WHEN response_rate >= 0.80 THEN 'Good (80-89%)'
        WHEN response_rate >= 0.70 THEN 'Fair (70-79%)'
        ELSE 'Poor (<70%)'
    END
ORDER BY avg_revenue_per_host DESC;

-- Superhost vs Regular host comparison
SELECT
    CASE
        WHEN h.is_superhost THEN 'Superhost'
        ELSE 'Regular Host'
    END as host_type,
    COUNT(DISTINCT h.host_id) as total_hosts,
    COUNT(b.booking_id) as total_bookings,
    SUM(b.total_booking_amount) as total_revenue,
    AVG(b.total_booking_amount) as avg_booking_value,
    COUNT(DISTINCT b.listing_id) as unique_listings_booked,
    ROUND(AVG(h.response_rate) * 100, 1) as avg_response_rate
FROM {{ ref('silver_hosts') }} h
LEFT JOIN {{ ref('obt') }} b ON h.host_id = b.host_id
GROUP BY
    CASE
        WHEN h.is_superhost THEN 'Superhost'
        ELSE 'Regular Host'
    END
ORDER BY total_revenue DESC;

-- Host occupancy rates (bookings per listing)
SELECT
    h.host_id,
    h.host_name,
    COUNT(DISTINCT l.listing_id) as total_listings,
    COUNT(b.booking_id) as total_bookings,
    ROUND(COUNT(b.booking_id) * 1.0 / NULLIF(COUNT(DISTINCT l.listing_id), 0), 2) as bookings_per_listing,
    SUM(b.total_booking_amount) as total_revenue,
    ROUND(SUM(b.total_booking_amount) / NULLIF(COUNT(DISTINCT l.listing_id), 0), 2) as revenue_per_listing
FROM {{ ref('silver_hosts') }} h
LEFT JOIN {{ ref('silver_listing') }} l ON h.host_id = l.host_id
LEFT JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
GROUP BY h.host_id, h.host_name
HAVING total_listings > 0
ORDER BY bookings_per_listing DESC
LIMIT 20;