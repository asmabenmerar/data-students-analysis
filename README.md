# Profil sociodémographique des étudiants Data OpenClassrooms (2022-2025)

Pipeline dbt (Snowflake) qui nettoie, fiabilise et analyse le profil des inscrits
aux parcours Data, puis le compare à la population française (INSEE).

## Architecture

| Couche | Modèle | Rôle |
|---|---|---|
| Source | `RAW_STUDENTS` | Inscriptions OpenClassrooms (4 647 lignes) |
| Source | `RAW_INSEE_POPULATION` | Population INSEE par région, sexe et âge, 2022-2025 (2 880 lignes) |
| Staging | `stg_students` | Nettoyage, pseudonymisation SHA-256 avec sel, genre normalisé |
| Staging | `stg_insee_population` | Harmonisation des catégories INSEE avec OpenClassrooms |
| Intermediate | `int_enrollments` | Rang d'inscription, statut Nouveau/Revenant, regroupements d'âge |
| Marts | `fct_enrollments` | Une ligne par inscription (table interne, non diffusée) |
| Marts | `mart_profile_by_year` | Profil par année : âge, genre, région, statut (diffusable) |
| Marts | `mart_comparison_oc_insee` | Parts OC vs INSEE et indice de représentation (diffusable) |

## Reproduire le pipeline

1. **Charger les données dans Snowflake**, base `OPENCLASSROOMS_DB`, schéma `STUDENT_ANALYSIS`
   (Ingestion > Add Data > Load data into a Table, en-tête sur la première ligne) :
   - `DATASET-MAJ-P8-1040-DA-DATA.csv` → table `RAW_STUDENTS`
   - `insee_population_region_sexe_age_2022_2025.csv` → table `RAW_INSEE_POPULATION`
     (préparé à partir du fichier INSEE `estim-pop-nreg-sexe-aq-1975-2026.xlsx` :
     feuilles 2022 à 2025 mises au format long, lignes de total retirées)
2. **Vérifier la variable** `hash_salt` dans `dbt_project.yml` (sel de pseudonymisation).
3. **Lancer** `dbt build` : construit les modèles et exécute tous les tests
   (64 éléments, 0 erreur attendue).

## Exporter le jeu de données final

Dans Snowflake, exécuter :

```sql
select * from OPENCLASSROOMS_DB.<schéma dbt>.MART_PROFILE_BY_YEAR;
select * from OPENCLASSROOMS_DB.<schéma dbt>.MART_COMPARISON_OC_INSEE;
```

puis cliquer sur l'icône de téléchargement des résultats, au format CSV.
Seules ces deux tables agrégées sont diffusées ; `fct_enrollments` reste interne.

## Contrôles qualité

- Tests `not_null` et `accepted_values` sur toutes les dimensions (âge, genre, région, année).
- `assert_fct_enrollments_grain` : une seule inscription par étudiant et par année.
- `assert_volume_source_vs_fct` : aucune ligne perdue entre la source et la table de faits.
- `assert_parts_sum_to_100` : les parts de chaque année totalisent 100 %.
- `assert_mart_totals_match_fct` : les effectifs du mart égalent les inscriptions de l'année.

## Choix méthodologiques

- **Indicateur** : nombre d'inscriptions par année. Un étudiant ne s'inscrit qu'une fois par an,
  donc cela équivaut au nombre d'étudiants actifs de l'année.
- **Genre non renseigné** (26,8 % des lignes) : conservé sous « Non renseigné », jamais supprimé.
  La part de femmes est aussi calculée parmi les genres renseignés.
- **Comparaison INSEE** : population de 20 ans ou plus, hors Corse (absente des données OC),
  DOM regroupés en DROM, 55 ans et plus regroupés.
  `representation_index = 100 x part OC / part INSEE` (100 = même proportion que la population).

## RGPD

- `USER_ID` remplacé par une clé SHA-256 salée ; aucun identifiant direct dans les modèles.
- Effectifs inférieurs à 5 masqués (`is_suppressed`) dans les tables diffusées.
- Dimensions agrégées séparément (sans croisement) pour limiter les petits effectifs.
- Données INSEE agrégées et publiques : aucune donnée personnelle.
- Limite : le sel est stocké dans `dbt_project.yml` ; en production, il serait placé
  dans une variable d'environnement.

## Limites

- Populations INSEE au 1er janvier, provisoires pour 2024 et 2025.
- La population de référence est l'ensemble des 20 ans ou plus, pas seulement
  les personnes en reconversion.
- La tranche d'âge d'un étudiant ne change pas d'une année à l'autre dans la source.