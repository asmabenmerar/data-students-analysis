-- Table de comparaison entre le profil des inscrits OpenClassrooms (OC) et la population française (INSEE)
-- Je la matérialise en table pour pouvoir l'exporter et la diffuser
{{ config(materialized='table') }}

-- Seuil de masquage RGPD défini une seule fois : les effectifs inférieurs à 5 sont masqués
{% set k = 5 %}

-- ÉTAPE 1 : effectifs OpenClassrooms par année, dimension et modalité
-- Chaque dimension est comptée séparément (sans croisement) pour éviter les petits effectifs
with oc as (

    -- Âge : je prends la tranche regroupée (55 ans et plus), la même que celle de l'INSEE
    select enrollment_year as year, 'Age' as dimension, age_group_diffusion as modality, count(*) as n
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

    union all

    -- genre : uniquement les genres renseignés, pour comparer avec l'INSEE
    -- (l'INSEE n'a pas de catégorie « Non renseigné »)
    select enrollment_year, 'Genre', gender, count(*)
    from {{ ref('fct_enrollments') }}
    where gender <> 'Non renseigné'
    group by 1, 2, 3

    union all

    -- Région : les 13 régions d'OpenClassrooms
    select enrollment_year, 'Region', region, count(*)
    from {{ ref('fct_enrollments') }}
    group by 1, 2, 3

),

-- ÉTAPE 2 : part de chaque modalité chez OpenClassrooms (en %)
-- sum(n) over (partition by ...) donne le total de l'année et de la dimension,
-- donc les parts d'une même dimension totalisent 100 %
oc_share as (
    select *, 100.0 * n / sum(n) over (partition by year, dimension) as oc_pct
    from oc
),

-- ÉTAPE 3 : population INSEE par année, dimension et modalité
-- Je reprends exactement les mêmes dimensions et libellés que côté OpenClassrooms
-- pour que la jointure fonctionne
insee as (

    -- Âge : tranches regroupées de la même façon que chez OpenClassrooms
    select year, 'Age' as dimension, age_group_diffusion as modality, sum(population) as pop
    from {{ ref('stg_insee_population') }}
    group by 1, 2, 3

    union all

    -- Genre : femmes et hommes
    select year, 'Genre', gender, sum(population)
    from {{ ref('stg_insee_population') }}
    group by 1, 2, 3

    union all

    -- Région : populations régionales
    select year, 'Region', region, sum(population)
    from {{ ref('stg_insee_population') }}
    group by 1, 2, 3

),

-- ÉTAPE 4 : part de chaque modalité dans la population INSEE (en %)
insee_share as (
    select *, 100.0 * pop / sum(pop) over (partition by year, dimension) as insee_pct
    from insee
)

-- ÉTAPE 5 : je rapproche les deux parts et je calcule l'indice de représentation
select
    o.year,
    o.dimension,
    o.modality,
    -- Règle RGPD : effectif et part OC masqués (vides) quand l'effectif est inférieur à 5
    case when o.n >= {{ k }} then o.n end                                  as nb_enrollments,
    case when o.n >= {{ k }} then round(o.oc_pct, 1) end                   as oc_share_pct,
    -- Données INSEE : population et part, publiques et agrégées, donc jamais masquées
    i.pop                                                                  as insee_population,
    round(i.insee_pct, 1)                                                  as insee_share_pct,
    -- Indice de représentation : 100 = même proportion que dans la population,
    -- au-dessus de 100 = sur-représenté, en dessous = sous-représenté
    case when o.n >= {{ k }} then round(100 * o.oc_pct / i.insee_pct, 0) end as representation_index,
    -- Indicateur de masquage pour savoir quelles lignes sont protégées
    o.n < {{ k }}                                                          as is_suppressed
from oc_share o
-- Jointure sur l'année, la dimension et la modalité : les libellés doivent être identiques des deux côtés
join insee_share i
  on  o.year = i.year
  and o.dimension = i.dimension
  and o.modality = i.modality