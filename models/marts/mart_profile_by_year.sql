with base as (
    select enrollment_year, 'Age' as dimension, age_group as modality, count(*) as n
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
)

select
    b.enrollment_year,
    b.dimension,
    b.modality,
    case when b.n >= 5 then b.n end                             as nb_enrollments,
    case when b.n >= 5 then round(100.0 * b.n / t.total, 1) end as share_pct,
    b.n < 5                                                     as is_suppressed
from base b
join tot t using (enrollment_year)