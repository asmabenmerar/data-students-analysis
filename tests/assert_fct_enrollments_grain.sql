select student_key, enrollment_year, count(*) as nb
from {{ ref('fct_enrollments') }}
group by 1, 2
having count(*) > 1

-- Contrôle de granularité : détecte les doublons sur la clé
-- (student_key, enrollment_year) dans fct_enrollments.