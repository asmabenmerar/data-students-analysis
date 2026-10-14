select
    *,
    case when left(age_group, 2) in ('20', '25', '30', '35')
         then 'Moins de 40 ans'
         else '40 ans et plus'
    end as age_band_40,
    row_number() over (
        partition by student_key
        order by enrollment_year
    ) as enrollment_rank
from {{ ref('stg_students') }}