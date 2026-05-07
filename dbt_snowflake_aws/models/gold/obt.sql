{% set configs = [
    {
        "table": "{{ ref('silver_booking') }}",
        "columns": "silver_booking.*",
        "alias": "silver_booking"
    },
    {
        "table": "{{ ref('silver_listing') }}",
        "columns": "silver_listing.listing_id as list_id, silver_listing.host_id as h_id, silver_listing.property_type, silver_listing.room_type, silver_listing.city, silver_listing.country, silver_listing.bedrooms, silver_listing.bathrooms, silver_listing.price_per_night, silver_listing.price_category, silver_listing.created_at as listing_created_at",
        "alias": "silver_listing",
        "join_condition": "silver_booking.listing_id = silver_listing.listing_id"
    },
    {
        "table": "{{ ref('silver_hosts') }}",
        "columns": "silver_hosts.host_id, silver_hosts.host_name, silver_hosts.host_since, silver_hosts.is_superhost, silver_hosts.response_rate, silver_hosts.response_rate_category, silver_hosts.created_at as host_created_at",
        "alias": "silver_hosts",
        "join_condition": "silver_listing.host_id = silver_hosts.host_id"
    }
] %}

select
    {% for config in configs %}
        {{ config['columns'] }}{% if not loop.last %}, {% endif %}
    {% endfor %}
from
    {% for config in configs %}
    {% if loop.first %}
        {{ config['table'] }} as {{ config['alias'] }}
    {% else %}
        left join {{ config['table'] }} as {{ config['alias'] }}
        on {{ config['join_condition'] }}
    {% endif %}
{% endfor %}

