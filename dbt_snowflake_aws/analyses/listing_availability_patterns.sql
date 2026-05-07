-- ===========================================
-- LISTING AVAILABILITY PATTERNS
-- ===========================================

-- Listing utilization rates (booking frequency)
SELECT
    l.listing_id,
    l.listing_name,
    l.price_per_night,
    COUNT(b.booking_id) as total_bookings,
    COUNT(DISTINCT DATE_TRUNC('month', b.booking_date)) as active_months,
    ROUND(COUNT(b.booking_id) * 1.0 / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', b.booking_date)), 0), 2) as avg_bookings_per_active_month,
    SUM(b.total_booking_amount) as total_revenue,
    ROUND(AVG(b.total_booking_amount), 2) as avg_booking_value,
    CASE
        WHEN COUNT(b.booking_id) = 0 THEN 'No Bookings'
        WHEN COUNT(b.booking_id) <= 5 THEN 'Low Activity'
        WHEN COUNT(b.booking_id) <= 20 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END as activity_level
FROM {{ ref('silver_listing') }} l
LEFT JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
GROUP BY l.listing_id, l.listing_name, l.price_per_night
ORDER BY total_bookings DESC;

-- Price vs booking frequency analysis
SELECT
    CASE
        WHEN price_per_night < 50 THEN 'Budget (<$50)'
        WHEN price_per_night < 100 THEN 'Economy ($50-$99)'
        WHEN price_per_night < 200 THEN 'Mid-range ($100-$199)'
        WHEN price_per_night < 500 THEN 'Premium ($200-$499)'
        ELSE 'Luxury ($500+)'
    END as price_category,
    COUNT(DISTINCT l.listing_id) as total_listings,
    COUNT(b.booking_id) as total_bookings,
    ROUND(COUNT(b.booking_id) * 1.0 / COUNT(DISTINCT l.listing_id), 2) as avg_bookings_per_listing,
    AVG(l.price_per_night) as avg_price,
    SUM(b.total_booking_amount) as total_revenue,
    ROUND(SUM(b.total_booking_amount) / COUNT(DISTINCT l.listing_id), 2) as avg_revenue_per_listing
FROM {{ ref('silver_listing') }} l
LEFT JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
GROUP BY
    CASE
        WHEN price_per_night < 50 THEN 'Budget (<$50)'
        WHEN price_per_night < 100 THEN 'Economy ($50-$99)'
        WHEN price_per_night < 200 THEN 'Mid-range ($100-$199)'
        WHEN price_per_night < 500 THEN 'Premium ($200-$499)'
        ELSE 'Luxury ($500+)'
    END
ORDER BY avg_bookings_per_listing DESC;

-- Seasonal availability patterns by property type
SELECT
    l.property_type,
    MONTH(b.booking_date) as booking_month,
    MONTHNAME(b.booking_date) as month_name,
    COUNT(DISTINCT l.listing_id) as active_listings,
    COUNT(b.booking_id) as total_bookings,
    ROUND(COUNT(b.booking_id) * 1.0 / COUNT(DISTINCT l.listing_id), 2) as avg_bookings_per_listing,
    SUM(b.total_booking_amount) as monthly_revenue
FROM {{ ref('silver_listing') }} l
JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
GROUP BY l.property_type, MONTH(b.booking_date), MONTHNAME(b.booking_date)
ORDER BY l.property_type, booking_month;

-- Bedroom/bathroom impact on booking rates
SELECT
    CONCAT(l.bedrooms, 'BR/', l.bathrooms, 'BA') as room_config,
    COUNT(DISTINCT l.listing_id) as total_listings,
    COUNT(b.booking_id) as total_bookings,
    ROUND(COUNT(b.booking_id) * 1.0 / COUNT(DISTINCT l.listing_id), 2) as bookings_per_listing,
    AVG(l.price_per_night) as avg_price,
    SUM(b.total_booking_amount) as total_revenue,
    ROUND(SUM(b.total_booking_amount) / COUNT(DISTINCT l.listing_id), 2) as revenue_per_listing
FROM {{ ref('silver_listing') }} l
LEFT JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
WHERE l.bedrooms IS NOT NULL AND l.bathrooms IS NOT NULL
GROUP BY l.bedrooms, l.bathrooms
HAVING total_listings >= 5
ORDER BY bookings_per_listing DESC;

-- Listing performance over time (cohort analysis)
WITH monthly_listing_performance AS (
    SELECT
        l.listing_id,
        DATE_TRUNC('month', b.booking_date) as booking_month,
        COUNT(b.booking_id) as monthly_bookings,
        SUM(b.total_booking_amount) as monthly_revenue
    FROM {{ ref('silver_listing') }} l
    JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
    GROUP BY l.listing_id, DATE_TRUNC('month', b.booking_date)
)
SELECT
    listing_id,
    COUNT(DISTINCT booking_month) as active_months,
    SUM(monthly_bookings) as total_bookings,
    SUM(monthly_revenue) as total_revenue,
    ROUND(AVG(monthly_bookings), 2) as avg_monthly_bookings,
    ROUND(STDDEV(monthly_bookings), 2) as booking_volatility,
    CASE
        WHEN COUNT(DISTINCT booking_month) >= 6 THEN 'Consistent'
        WHEN COUNT(DISTINCT booking_month) >= 3 THEN 'Moderate'
        ELSE 'Inconsistent'
    END as consistency_rating
FROM monthly_listing_performance
GROUP BY listing_id
HAVING active_months >= 1
ORDER BY avg_monthly_bookings DESC;