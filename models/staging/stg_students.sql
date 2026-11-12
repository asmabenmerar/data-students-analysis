-- Staging : première couche de transformation, qui nettoie la table brute RAW_STUDENTS
-- Aucune donnée directement identifiante n'est conservée : l'identifiant est pseudonymisé

select
    -- Identifiant pseudonymisé : je colle un « sel » secret à l'identifiant (concat),
    -- puis je le transforme avec SHA-256, ce qui est irréversible
    -- Le sel (variable hash_salt, lue avec var()) empêche de retrouver l'identifiant d'origine
    -- en testant des identifiants connus
    sha2(concat(trim(USER_ID), '{{ var("hash_salt") }}'), 256) as student_key,

    -- trim() enlève les espaces parasites pour éviter des modalités en double
    trim(PATH_CATEGORY_NAME)          as path_category,
    trim(AGE_GROUP)                   as age_group,

    -- Genre : je recode les lettres en libellés lisibles
    -- upper(trim()) rend le test insensible aux espaces et à la casse (f ou F)
    -- Tout ce qui n'est ni F ni M (valeurs vides, 1 246 lignes) devient « Non renseigné » :
    -- je ne supprime jamais ces lignes (consigne de la mentor)
    case upper(trim(GENDER))
        when 'F' then 'Femme'
        when 'M' then 'Homme'
        else 'Non renseigné'
    end                               as gender,

    trim(REGION)                      as region,
    -- Année de début du parcours : conservée telle quelle
    YEAR_PATH_STARTED                 as enrollment_year
-- source() appelle la table brute déclarée dans sources.yml (source « raw_data », table RAW_STUDENTS)
from {{ source('raw_data', 'RAW_STUDENTS') }}