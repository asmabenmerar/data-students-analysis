select
    sha2(trim(USER_ID), 256)          as student_key,
    trim(PATH_CATEGORY_NAME)          as path_category,
    trim(AGE_GROUP)                   as age_group,
    case upper(trim(GENDER))
        when 'F' then 'Femme'
        when 'M' then 'Homme'
        else 'Non renseigné'
    end                               as gender,
    trim(REGION)                      as region,
    YEAR_PATH_STARTED                 as enrollment_year
from {{ source('raw_data', 'RAW_STUDENTS') }}