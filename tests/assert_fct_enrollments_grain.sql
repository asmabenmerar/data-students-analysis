-- Test de grain sur la table de faits : un étudiant ne doit apparaître
-- qu'une seule fois par année dans fct_enrollments
-- Un test dbt de ce type réussit quand il ne renvoie aucune ligne,
-- donc il échoue seulement si des doublons sont détectés

select
    student_key,
    enrollment_year,
    -- Nombre de lignes pour ce couple étudiant et année : il doit toujours valoir 1
    count(*) as nb
-- Je lis la table finale (ref() relie ce test au modèle)
from {{ ref('fct_enrollments') }}
group by 1, 2
-- Je ne garde que les couples présents plusieurs fois
-- Un doublon fausserait les effectifs du mart et les parts calculées
having count(*) > 1

-- Contrôle de granularité : détecte les doublons sur la clé
-- (student_key, enrollment_year) dans fct_enrollments.