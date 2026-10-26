select student_key, enrollment_year, count(*) as nb
from {{ ref('fct_enrollments') }}
group by 1, 2
having count(*) > 1