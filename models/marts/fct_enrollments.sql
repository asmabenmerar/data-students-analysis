select
    student_key,
    age_group,
    age_band_40,
    gender,
    region,
    enrollment_year,
    enrollment_rank
from {{ ref('int_enrollments') }}