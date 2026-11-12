-- Test de cohérence sur les parts : pour chaque année et chaque dimension
-- (âge, genre, région, statut), les parts de toutes les modalités doivent faire environ 100 %
-- Un test dbt de ce type réussit quand il ne renvoie aucune ligne,
-- donc il échoue seulement si une somme sort de la fourchette prévue

select
    enrollment_year,
    dimension,
    -- Somme des parts de toutes les modalités d'une même dimension et d'une même année
    sum(share_pct) as somme_parts
-- Je lis le mart de profil par année (ref() relie ce test au modèle)
from {{ ref('mart_profile_by_year') }}
group by 1, 2
-- Je ne garde que les cas anormaux : somme sous 99 % ou au-dessus de 101 %
-- La tolérance de 1 point couvre les arrondis à une décimale
-- et les éventuelles cellules masquées (effectif inférieur à 5), qui ne sont pas comptées
having sum(share_pct) < 99 or sum(share_pct) > 101

-- Contrôle de cohérence métier :
-- la somme des pourcentages par année et dimension doit être comprise entre 99 % et 101 %.