{{ config(materialized='table') }}
{% set k = 5 %}

with oc as (

    select enrollment_year as year, 'Age' as dimension, age_group_diffusion as modality, count(*) as n
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

    union all

    -- genre : uniquement les genres renseignés, pour comparer avec l'INSEE
    select enrollment_year, 'Genre', gender, count(*)
    from {{ ref('fct_enrollments') }}
    where gender <> 'Non renseigné'
    group by 1, 2, 3

    union all

    select enrollment_year, 'Region', region, count(*)
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

),

oc_share as (
    select *, 100.0 * n / sum(n) over (partition by year, dimension) as oc_pct
    from oc
),

insee as (

    select year, 'Age' as dimension, age_group_diffusion as modality, sum(population) as pop
    from {{ ref('stg_insee_population') }}
    group by 1, 2, 3

    union all

    select year, 'Genre', gender, sum(population)
    from {{ ref('stg_insee_population') }}
    group by 1, 2, 3

    union all

    select year, 'Region', region, sum(population)
    from {{ ref('stg_insee_population') }}
    group by 1, 2, 3

),

insee_share as (
    select *, 100.0 * pop / sum(pop) over (partition by year, dimension) as insee_pct
    from insee
)

select
    o.year,
    o.dimension,
    o.modality,
    case when o.n >= {{ k }} then o.n end                                  as nb_enrollments,
    case when o.n >= {{ k }} then round(o.oc_pct, 1) end                   as oc_share_pct,
    i.pop                                                                  as insee_population,
    round(i.insee_pct, 1)                                                  as insee_share_pct,
    case when o.n >= {{ k }} then round(100 * o.oc_pct / i.insee_pct, 0) end as representation_index,
    o.n < {{ k }}                                                          as is_suppressed
from oc_share o
join insee_share i
  on  o.year = i.year
  and o.dimension = i.dimension
  and o.modality = i.modality