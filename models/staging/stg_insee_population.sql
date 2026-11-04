with src as (

    select
        YEAR                                              as year,
        trim(REGION)                                      as region_insee,
        trim(SEX)                                         as sex_insee,
        trim(AGE_GROUP)                                   as age_insee,
        try_to_number(split_part(trim(AGE_GROUP), ' ', 1)) as age_min,
        POPULATION                                        as population
    from {{ source('raw_data', 'RAW_INSEE_POPULATION') }}

),

harmonized as (

    select
        year,
        case
            when region_insee = 'Centre-Val-de-Loire' then 'Centre-Val de Loire'
            when region_insee in ('Guadeloupe', 'Martinique', 'Guyane', 'La Réunion', 'Mayotte') then 'DROM'
            else region_insee
        end as region,
        case sex_insee
            when 'Hommes' then 'Homme'
            when 'Femmes' then 'Femme'
        end as gender,
        case
            when age_min >= 60 then '60 ans ou plus'
            else replace(age_insee, ' à ', '-')
        end as age_group,
        population
    from src
    where age_min >= 20              -- les étudiants ont 20 ans ou plus
      and region_insee <> 'Corse'    -- absente des données OpenClassrooms

)

select
    year,
    region,
    gender,
    age_group,
    case
        when age_group in ('55-59 ans', '60 ans ou plus') then '55 ans et plus'
        else age_group
    end as age_group_diffusion,
    sum(population) as population
from harmonized
group by 1, 2, 3, 4, 5