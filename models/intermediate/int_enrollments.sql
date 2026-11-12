-- Modèle intermédiaire : il part de stg_students (déjà nettoyé et pseudonymisé)
-- et ajoute mes règles métier avant la table finale

-- Première étape (CTE « base ») : je calcule le rang d'inscription de chaque étudiant
with base as (

    select
        *,
        -- Je numérote les inscriptions de chaque étudiant (partition by student_key),
        -- de la plus ancienne à la plus récente (order by enrollment_year)
        -- 1 = première inscription, 2 = réinscription, etc.
        -- Avec rang = 1, je peux compter les étudiants distincts (4 010)
        row_number() over (
            partition by student_key
            order by enrollment_year
        ) as enrollment_rank
    from {{ ref('stg_students') }}  -- ref() relie ce modèle au staging

)

-- Deuxième étape : je garde toutes les colonnes de « base » et j'ajoute trois colonnes
select
    *,

    -- Regroupement en 2 classes d'âge, plus lisible pour un public non technique
    -- left(age_group, 2) prend les deux premiers caractères de la tranche (ex. « 30 » dans « 30-34 ans »)
    case
        when left(age_group, 2) in ('20', '25', '30', '35') then 'Moins de 40 ans'
        else '40 ans et plus'
    end as age_band_40,

    -- Tranche d'âge pour les sorties diffusées (RGPD)
    -- Je regroupe 55-59 ans et 60 ans ou plus, car cette dernière tranche
    -- n'avait que 3 personnes en 2024 (moins de 5), donc risque de réidentification
    -- Les autres tranches restent inchangées
    case
        when age_group in ('55-59 ans', '60 ans ou plus') then '55 ans et plus'
        else age_group
    end as age_group_diffusion,

    -- Statut lisible pour la présentation : Revenant dès la 2e inscription, sinon Nouveau
    case
        when enrollment_rank > 1 then 'Revenant'
        else 'Nouveau'
    end as student_status
from base