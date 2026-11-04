{{ config(materialized='table') }}
{% set k = 5 %}

with base as (

    select enrollment_year, 'Age' as dimension, age_group_diffusion as modality, count(*) as n
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

    union all

    select enrollment_year, 'Genre', gender, count(*)
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

    union all

    select enrollment_year, 'Region', region, count(*)
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

),

tot as (
    select enrollment_year, count(*) as total
    from {{ ref('fct_enrollments') }}
    group by 1
),

tot_known as (
    select enrollment_year, count(*) as total_known
    from {{ ref('fct_enrollments') }}
    where gender <> 'Non renseigné'
    group by 1
)

select
    b.enrollment_year,
    b.dimension,
    b.modality,
    case when b.n >= {{ k }} then b.n end                                  as nb_enrollments,
    case when b.n >= {{ k }} then round(100.0 * b.n / t.total, 1) end      as share_pct,
    case
        when b.dimension = 'Genre'
         and b.modality <> 'Non renseigné'
         and b.n >= {{ k }}
        then round(100.0 * b.n / tk.total_known, 1)
    end                                                                    as share_known_gender_pct,
    b.n < {{ k }}                                                          as is_suppressed
from base b
join tot t using (enrollment_year)
join tot_known tk using (enrollment_year)