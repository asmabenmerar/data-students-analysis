-- Pour chaque année et chaque dimension, la somme des effectifs du mart
-- doit être égale au nombre d'inscriptions dans fct_enrollments.
with m as (
    select enrollment_year, dimension, sum(nb_enrollments) as n_mart
    from {{ ref('mart_profile_by_year') }}
    group by 1, 2
),

f as (
    select enrollment_year, count(*) as n_fct
    from {{ ref('fct_enrollments') }}
    group by 1
)

select m.enrollment_year, m.dimension, m.n_mart, f.n_fct
from m
join f using (enrollment_year)
where m.n_mart <> f.n_fct