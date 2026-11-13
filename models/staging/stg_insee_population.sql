-- Staging des données INSEE : je prépare la population française pour la comparer à celle d'OpenClassrooms
-- Les libellés (régions, genre, tranches d'âge) doivent être identiques des deux côtés,
-- sinon la jointure du mart de comparaison perd des lignes

-- ÉTAPE 1 : je lis la table brute INSEE chargée dans Snowflake (source déclarée dans sources.yml)
-- et je renomme les colonnes en minuscules
with src as (

    select
        YEAR                                              as year,
        -- trim() enlève les espaces parasites dans les textes
        -- je nomme la colonne region_insee pour la distinguer de la région harmonisée de l'étape 2
        trim(REGION)                                      as region_insee,
        trim(SEX)                                         as sex_insee,
        trim(AGE_GROUP)                                   as age_insee,
        -- J'extrais l'âge minimum de la tranche (premier mot avant l'espace) :
        -- « 20 à 24 ans » donne 20, « 60 ans ou plus » donne 60
        -- try_to_number renvoie vide (null) au lieu d'une erreur si le premier mot n'est pas un nombre
        try_to_number(split_part(trim(AGE_GROUP), ' ', 1)) as age_min,
        POPULATION                                        as population
    from {{ source('raw_data', 'RAW_INSEE_POPULATION') }}

),

-- ÉTAPE 2 : j'harmonise les catégories INSEE avec celles d'OpenClassrooms
harmonized as (

    select
        year,
        -- Région : je corrige l'écriture de « Centre-Val de Loire » (tirets chez l'INSEE)
        -- et je regroupe les 5 départements d'outre-mer sous « DROM », comme dans mes données internes
        case
            when region_insee = 'Centre-Val-de-Loire' then 'Centre-Val de Loire'
            when region_insee in ('Guadeloupe', 'Martinique', 'Guyane', 'La Réunion', 'Mayotte') then 'DROM'
            else region_insee
        end as region,
        -- Genre : « Hommes » et « Femmes » (pluriel chez l'INSEE) deviennent « Homme » et « Femme »
        case sex_insee
            when 'Hommes' then 'Homme'
            when 'Femmes' then 'Femme'
        end as gender,
        -- Âge : à partir de 60 ans, tout est regroupé en « 60 ans ou plus », comme chez OpenClassrooms
        -- Sinon, « 20 à 24 ans » devient « 20-24 ans » pour avoir le même libellé que mes données
        case
            when age_min >= 60 then '60 ans ou plus'
            else replace(age_insee, ' à ', '-')
        end as age_group,
        population
    from src
    -- Je garde la population de 20 ans ou plus, car mes étudiants ont 20 ans ou plus
    -- (les lignes dont l'âge n'est pas un nombre, comme « Moins de 20 ans », sont aussi écartées ici)
    where age_min >= 20
      -- J'exclus la Corse : elle n'existe pas dans les données OpenClassrooms,
      -- ce qui évite une région sans équivalent à comparer
      and region_insee <> 'Corse'

)

-- ÉTAPE 3 : résultat final : population par année, région, genre et tranche d'âge
select
    year,
    region,
    gender,
    age_group,
    -- Tranche d'âge pour la diffusion : 55-59 ans et 60 ans ou plus regroupés en « 55 ans et plus »
    -- Même règle que dans int_enrollments, pour que la comparaison porte sur les mêmes tranches
    case
        when age_group in ('55-59 ans', '60 ans ou plus') then '55 ans et plus'
        else age_group
    end as age_group_diffusion,
    -- Je somme la population, car après regroupement (DROM, 60 ans ou plus)
    -- plusieurs lignes de la source tombent dans une même catégorie
    sum(population) as population
from harmonized
group by 1, 2, 3, 4, 5