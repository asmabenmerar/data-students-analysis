select year, region, gender, age_group, count(*) as nb
from {{ ref('stg_insee_population') }}
group by 1, 2, 3, 4
having count(*) > 1