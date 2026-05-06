{% set configs = [
    {
        "table":'airbnb.gold.obt',
        "columns":"gold_obt.booking_id, gold_obt.listing_id, gold_obt.host_id, gold_obt.total_booking_amount, gold_obt.cleaning_fee, gold_obt.service_fee, gold_obt.bedrooms, gold_obt.bathrooms, gold_obt.price_per_night, gold_obt.response_rate",
        "alias":'gold_obt'
    },
    {
        "table":'airbnb.gold.dim_listings',
        "columns":"",
        "alias":'dim_listings',
        "join_condition":'gold_obt.listing_id = dim_listings.listing_id'
    },
    {
        "table":'airbnb.gold.dim_hosts',
        "columns":"",
        "alias":'dim_hosts',
        "join_condition":'gold_obt.host_id = dim_hosts.host_id'
    }
] %}

select

        {{ configs[0]['columns'] }}

from 
    {% for config in configs %}
    {% if loop.first %}
        {{ config['table'] }} as {{ config['alias'] }}
    {% else %}
        left join {{ config['table'] }} as {{ config['alias'] }}
        on {{ config['join_condition'] }}
    {% endif %}
{% endfor %}

