{# select *
from {{ ref('bronze_bookings') }} #}

{# select *
from {{ ref('bronze_listings') }} #}

{# select *
from {{ ref ('bronze_hosts')}} #}

select *
from {{ ref('silver_listing') }} 