select n_source, n_fct
from (
    select
        (select count(*) from {{ source('raw_data', 'RAW_STUDENTS') }}) as n_source,
        (select count(*) from {{ ref('fct_enrollments') }})              as n_fct
)
where n_source <> n_fct

#vérifier que le nombre de lignes de la table source est identique au nombre de lignes chargées dans la table de faits (fct_enrollments).