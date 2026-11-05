select enrollment_year, dimension, sum(share_pct) as somme_parts
from {{ ref('mart_profile_by_year') }}
group by 1, 2
having sum(share_pct) < 99 or sum(share_pct) > 101

-- Contrôle de cohérence métier :
-- la somme des pourcentages par année et dimension doit être comprise entre 99 % et 101 %.