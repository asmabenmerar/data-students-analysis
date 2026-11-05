select year, region, gender, age_group, count(*) as nb
from {{ ref('stg_insee_population') }}
group by 1, 2, 3, 4
having count(*) > 1

-- Vérifie l'unicité de la granularité de la table INSEE.
-- Pour chaque combinaison (year, region, gender, age_group),
-- une seule ligne doit exister. Le test échoue si des doublons sont détectés.