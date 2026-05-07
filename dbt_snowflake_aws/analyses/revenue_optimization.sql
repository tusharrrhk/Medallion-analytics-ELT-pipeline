-- ===========================================
-- REVENUE OPTIMIZATION INSIGHTS
-- ===========================================

-- Optimal pricing analysis (price elasticity)
SELECT
    l.price_per_night,
    COUNT(b.booking_id) as booking_count,
    ROUND(COUNT(b.booking_id) * 1.0 / COUNT(DISTINCT l.listing_id), 2) as bookings_per_listing,
    SUM(b.total_booking_amount) as total_revenue,
    ROUND(SUM(b.total_booking_amount) / COUNT(DISTINCT l.listing_id), 2) as revenue_per_listing,
    ROUND(SUM(b.total_booking_amount) / COUNT(b.booking_id), 2) as avg_booking_value
FROM {{ ref('silver_listing') }} l
LEFT JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
GROUP BY l.price_per_night
HAVING COUNT(DISTINCT l.listing_id) >= 3
ORDER BY revenue_per_listing DESC;

-- Revenue by booking status (identifying lost revenue)
SELECT
    booking_status,
    COUNT(*) as booking_count,
    SUM(total_booking_amount) as total_amount,
    ROUND(SUM(total_booking_amount) * 100.0 / SUM(SUM(total_booking_amount)) OVER (), 2) as revenue_percentage,
    ROUND(AVG(total_booking_amount), 2) as avg_booking_value,
    CASE
        WHEN booking_status = 'cancelled' THEN 'Lost Revenue'
        WHEN booking_status = 'completed' THEN 'Realized Revenue'
        ELSE 'Potential Revenue'
    END as revenue_category
FROM {{ ref('obt') }}
GROUP BY booking_status
ORDER BY total_amount DESC;

-- High-value customer segments
WITH customer_segments AS (
    SELECT
        host_id,
        COUNT(*) as booking_count,
        SUM(total_booking_amount) as total_spent,
        AVG(total_booking_amount) as avg_booking_value,
        MAX(booking_date) as last_booking_date,
        MIN(booking_date) as first_booking_date,
        DATEDIFF('day', MIN(booking_date), MAX(booking_date)) as customer_lifespan_days
    FROM {{ ref('obt') }}
    GROUP BY host_id
)
SELECT
    CASE
        WHEN total_spent >= 10000 THEN 'VIP (>$10K)'
        WHEN total_spent >= 5000 THEN 'High Value ($5K-$10K)'
        WHEN total_spent >= 1000 THEN 'Medium Value ($1K-$5K)'
        ELSE 'Low Value (<$1K)'
    END as customer_segment,
    COUNT(*) as customer_count,
    SUM(booking_count) as total_bookings,
    SUM(total_spent) as total_revenue,
    ROUND(AVG(total_spent), 2) as avg_revenue_per_customer,
    ROUND(AVG(booking_count), 2) as avg_bookings_per_customer,
    ROUND(AVG(customer_lifespan_days), 0) as avg_customer_lifespan_days
FROM customer_segments
GROUP BY
    CASE
        WHEN total_spent >= 10000 THEN 'VIP (>$10K)'
        WHEN total_spent >= 5000 THEN 'High Value ($5K-$10K)'
        WHEN total_spent >= 1000 THEN 'Medium Value ($1K-$5K)'
        ELSE 'Low Value (<$1K)'
    END
ORDER BY total_revenue DESC;

-- Cancellation rate analysis by factors
SELECT
    l.property_type,
    COUNT(*) as total_bookings,
    SUM(CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_bookings,
    ROUND(SUM(CASE WHEN b.booking_status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as cancellation_rate,
    AVG(l.price_per_night) as avg_price,
    SUM(b.total_booking_amount) as total_booking_value,
    SUM(CASE WHEN b.booking_status = 'cancelled' THEN b.total_booking_amount ELSE 0 END) as lost_revenue
FROM {{ ref('silver_listing') }} l
JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
GROUP BY l.property_type
ORDER BY cancellation_rate DESC;

-- Revenue forecasting based on trends
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', booking_date) as revenue_month,
        SUM(total_booking_amount) as monthly_revenue,
        COUNT(*) as monthly_bookings
    FROM {{ ref('obt') }}
    WHERE booking_date >= DATEADD('month', -12, CURRENT_DATE())
    GROUP BY DATE_TRUNC('month', booking_date)
    ORDER BY revenue_month
),
revenue_trends AS (
    SELECT
        revenue_month,
        monthly_revenue,
        monthly_bookings,
        LAG(monthly_revenue) OVER (ORDER BY revenue_month) as prev_month_revenue,
        ROUND((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY revenue_month)) * 100.0 /
              NULLIF(LAG(monthly_revenue) OVER (ORDER BY revenue_month), 0), 2) as month_over_month_growth
    FROM monthly_revenue
)
SELECT
    revenue_month,
    monthly_revenue,
    monthly_bookings,
    month_over_month_growth,
    ROUND(AVG(monthly_revenue) OVER (ORDER BY revenue_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as moving_avg_3month,
    ROUND(AVG(month_over_month_growth) OVER (ORDER BY revenue_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as avg_growth_rate_3month
FROM revenue_trends
ORDER BY revenue_month DESC;

-- Optimal listing features for revenue maximization
SELECT
    CASE
        WHEN l.bedrooms >= 3 THEN '3+ Bedrooms'
        WHEN l.bedrooms = 2 THEN '2 Bedrooms'
        WHEN l.bedrooms = 1 THEN '1 Bedroom'
        ELSE 'Studio'
    END as bedroom_category,
    COUNT(DISTINCT l.listing_id) as listing_count,
    COUNT(b.booking_id) as total_bookings,
    ROUND(COUNT(b.booking_id) * 1.0 / COUNT(DISTINCT l.listing_id), 2) as bookings_per_listing,
    AVG(l.price_per_night) as avg_price,
    SUM(b.total_booking_amount) as total_revenue,
    ROUND(SUM(b.total_booking_amount) / COUNT(DISTINCT l.listing_id), 2) as revenue_per_listing,
    ROUND(SUM(b.total_booking_amount) / COUNT(b.booking_id), 2) as avg_booking_value
FROM {{ ref('silver_listing') }} l
LEFT JOIN {{ ref('obt') }} b ON l.listing_id = b.listing_id
GROUP BY
    CASE
        WHEN l.bedrooms >= 3 THEN '3+ Bedrooms'
        WHEN l.bedrooms = 2 THEN '2 Bedrooms'
        WHEN l.bedrooms = 1 THEN '1 Bedroom'
        ELSE 'Studio'
    END
ORDER BY revenue_per_listing DESC;