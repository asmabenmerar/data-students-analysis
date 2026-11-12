-- Pour chaque année et chaque dimension, la somme des effectifs du mart
-- doit être égale au nombre d'inscriptions dans fct_enrollments.

-- Test de cohérence des volumes entre la table finale et le mart agrégé :
-- il réussit quand il ne renvoie aucune ligne, donc il échoue
-- seulement si un total du mart ne correspond pas à celui de fct_enrollments

-- Total des effectifs du mart, par année et par dimension
with m as (
    -- Je somme les effectifs de toutes les modalités d'une dimension
    -- (par exemple toutes les régions de 2022 doivent donner 1 696)
    select enrollment_year, dimension, sum(nb_enrollments) as n_mart
    from {{ ref('mart_profile_by_year') }}
    group by 1, 2
),

-- Nombre réel d'inscriptions par année dans la table de faits
f as (
    select enrollment_year, count(*) as n_fct
    from {{ ref('fct_enrollments') }}
    group by 1
)

-- Je rapproche les deux totaux par année et je ne garde que les écarts :
-- chaque ligne renvoyée signale une année et une dimension où des inscriptions
-- ont été perdues ou comptées en trop dans le mart
select m.enrollment_year, m.dimension, m.n_mart, f.n_fct
from m
join f using (enrollment_year)
where m.n_mart <> f.n_fct