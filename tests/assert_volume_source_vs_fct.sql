-- Test de cohérence des volumes : je vérifie qu'aucune ligne n'a été perdue
-- entre la table source (RAW_STUDENTS) et la table de faits (fct_enrollments)
-- Un test dbt de ce type réussit quand il ne renvoie aucune ligne,
-- donc il échoue seulement si les deux nombres de lignes sont différents

select n_source, n_fct
from (
    select
        -- Nombre de lignes de la table brute importée dans Snowflake (4 647 attendues)
        (select count(*) from {{ source('raw_data', 'RAW_STUDENTS') }}) as n_source,
        -- Nombre de lignes de la table finale, après nettoyage et transformations
        (select count(*) from {{ ref('fct_enrollments') }})              as n_fct
)
-- Je ne garde que le cas anormal : si les deux nombres diffèrent, une ligne est renvoyée
-- et dbt signale un échec
where n_source <> n_fct