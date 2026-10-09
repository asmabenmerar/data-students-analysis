select
    USER_ID,
    PATH_CATEGORY_NAME,
    AGE_GROUP,
    GENDER,
    REGION,
    YEAR_PATH_STARTED

from {{ source('raw_data', 'RAW_STUDENTS') }}