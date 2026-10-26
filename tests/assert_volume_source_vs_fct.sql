select n_source, n_fct
from (
    select
        (select count(*) from {{ source('raw_data', 'RAW_STUDENTS') }}) as n_source,
        (select count(*) from {{ ref('fct_enrollments') }})              as n_fct
)
where n_source <> n_fct