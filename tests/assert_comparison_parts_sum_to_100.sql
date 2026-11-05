select year, dimension,
       sum(oc_share_pct)    as somme_oc,
       sum(insee_share_pct) as somme_insee
from {{ ref('mart_comparison_oc_insee') }}
group by 1, 2
having sum(oc_share_pct)    not between 99 and 101
    or sum(insee_share_pct) not between 99 and 101

    -- Contrôle de cohérence métier :
-- les répartitions OC et INSEE doivent totaliser entre 99 % et 101 %
-- par année et par dimension.