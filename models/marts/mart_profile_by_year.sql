-- Table d'agrégats pour la diffusion : pour chaque année, la répartition des inscriptions
-- par dimension (âge, genre, région, statut) et par modalité
-- Je la matérialise en table pour pouvoir l'exporter plus facilement
{{ config(materialized='table') }}

-- Seuil de masquage RGPD défini une seule fois : les groupes de moins de 5 personnes sont masqués
{% set k = 5 %}

-- ÉTAPE 1 : j'empile quatre comptages (un par dimension) au même format :
-- année, dimension, modalité, effectif (n)
-- Chaque dimension est comptée séparément, sans croisement, pour éviter les petits effectifs
with base as (

    -- Âge : tranche regroupée (55 ans et plus) pour éviter l'effectif inférieur à 5
    select enrollment_year, 'Age' as dimension, age_group_diffusion as modality, count(*) as n
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

    union all

    -- Genre : Femme, Homme et Non renseigné (je garde ce dernier pour montrer l'ampleur des valeurs manquantes)
    select enrollment_year, 'Genre', gender, count(*)
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

    union all

    -- Région : les 13 régions
    select enrollment_year, 'Region', region, count(*)
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

    union all

    -- Statut : Nouveau ou Revenant (dimension ajoutée pour distinguer les nouveaux étudiants des réinscrits)
    select enrollment_year, 'Statut', student_status, count(*)
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

),

-- ÉTAPE 2 : total des inscriptions par année, pour calculer les parts
tot as (
    select enrollment_year, count(*) as total
    from {{ ref('fct_enrollments') }}
    group by 1
),

-- ÉTAPE 3 : total des inscriptions dont le genre est renseigné, par année
-- Il sert de dénominateur pour la part parmi les genres connus
-- (sans lui, la hausse de la part de femmes serait trompeuse à cause de la baisse du genre manquant)
tot_known as (
    select enrollment_year, count(*) as total_known
    from {{ ref('fct_enrollments') }}
    where gender <> 'Non renseigné'
    group by 1
)

-- ÉTAPE 4 : je calcule les parts et j'applique la règle de masquage
select
    b.enrollment_year,
    b.dimension,
    b.modality,
    -- Règle RGPD : l'effectif est masqué (vide) quand il est inférieur à 5
    case when b.n >= {{ k }} then b.n end                                  as nb_enrollments,
    -- Part de la modalité dans toutes les inscriptions de l'année (aussi masquée sous 5)
    case when b.n >= {{ k }} then round(100.0 * b.n / t.total, 1) end      as share_pct,
    -- Part parmi les genres renseignés : seulement pour Femme et Homme
    -- (« Non renseigné » est exclu du dénominateur, donc sans part ici)
    case
        when b.dimension = 'Genre'
         and b.modality <> 'Non renseigné'
         and b.n >= {{ k }}
        then round(100.0 * b.n / tk.total_known, 1)
    end                                                                    as share_known_gender_pct,
    -- Indicateur de masquage : vrai quand le groupe est sous le seuil
    b.n < {{ k }}                                                          as is_suppressed
from base b
-- using (enrollment_year) rapproche chaque ligne du total de la même année
join tot t using (enrollment_year)
join tot_known tk using (enrollment_year)