with base as (

    select
        *,
        row_number() over (
            partition by student_key
            order by enrollment_year
        ) as enrollment_rank
    from {{ ref('stg_students') }}

)

select
    *,
    case
        when left(age_group, 2) in ('20', '25', '30', '35') then 'Moins de 40 ans'
        else '40 ans et plus'
    end as age_band_40,
    case
        when age_group in ('55-59 ans', '60 ans ou plus') then '55 ans et plus'
        else age_group
    end as age_group_diffusion,
    case
        when enrollment_rank > 1 then 'Revenant'
        else 'Nouveau'
    end as student_status
from base