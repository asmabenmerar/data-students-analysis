-- Test de cohérence sur la table de comparaison : pour chaque année et chaque dimension
-- (âge, genre, région), les parts d'OpenClassrooms et celles de l'INSEE doivent
-- chacune faire environ 100 %
-- Un test dbt de ce type réussit quand il ne renvoie aucune ligne,
-- donc il échoue seulement si une somme sort de la fourchette prévue

select
    year,
    dimension,
    -- Somme des parts OpenClassrooms de toutes les modalités de la dimension
    sum(oc_share_pct)    as somme_oc,
    -- Somme des parts INSEE de toutes les modalités de la dimension
    sum(insee_share_pct) as somme_insee
-- Je lis la table de comparaison (ref() relie ce test au modèle)
from {{ ref('mart_comparison_oc_insee') }}
group by 1, 2
-- Je ne garde que les cas anormaux : une somme en dehors de 99 à 101 %
-- La tolérance de 1 point couvre les arrondis à une décimale
having sum(oc_share_pct)    not between 99 and 101
    or sum(insee_share_pct) not between 99 and 101

    -- Contrôle de cohérence métier :
-- les répartitions OC et INSEE doivent totaliser entre 99 % et 101 %
-- par année et par dimension.