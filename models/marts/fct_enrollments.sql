{{ config(materialized='table') }}

select
    student_key,
    age_group,
    age_group_diffusion,
    age_band_40,
    gender,
    region,
    enrollment_year,
    enrollment_rank,
    student_status
from {{ ref('int_enrollments') }}