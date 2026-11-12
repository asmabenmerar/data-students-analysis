-- Test d'unicité (grain) sur la table INSEE préparée :
-- chaque combinaison année, région, genre et tranche d'âge doit apparaître une seule fois
-- Un test dbt de ce type réussit quand il ne renvoie aucune ligne,
-- donc il échoue seulement si des doublons sont détectés

select
    year, region, gender, age_group,
    -- Nombre de lignes pour cette combinaison : il doit toujours valoir 1
    count(*) as nb
-- Je lis le staging INSEE (ref() relie ce test au modèle)
from {{ ref('stg_insee_population') }}
group by 1, 2, 3, 4
-- Je ne garde que les combinaisons présentes plusieurs fois
-- Un doublon fausserait les populations et donc l'indice de représentation
having count(*) > 1

-- Vérifie l'unicité de la granularité de la table INSEE.
-- Pour chaque combinaison (year, region, gender, age_group),
-- une seule ligne doit exister. Le test échoue si des doublons sont détectés.