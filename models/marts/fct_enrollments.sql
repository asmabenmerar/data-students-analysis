-- Table finale (mart) : une ligne par inscription (étudiant x année)
-- Elle lit int_enrollments et ne garde que les colonnes utiles pour l'analyse
-- Aucune donnée directement identifiante : l'identifiant est déjà haché (student_key)

-- Je matérialise ce modèle en table (et non en vue, comme les autres modèles par défaut)
-- pour pouvoir l'exporter plus facilement en CSV à la fin du projet
{{ config(materialized='table') }}

select
    -- Identifiant étudiant pseudonymisé (SHA-256), créé dans stg_students
    student_key,
    -- Tranche d'âge détaillée (9 classes), pour l'usage interne
    age_group,
    -- Tranche d'âge regroupée (55 ans et plus), pour les sorties diffusées (RGPD)
    age_group_diffusion,
    -- Deux classes d'âge (moins de 40 ans / 40 ans et plus), pour montrer le rajeunissement
    age_band_40,
    -- Genre recodé : Femme, Homme ou Non renseigné
    gender,
    -- Région de résidence (13 modalités, DROM regroupés)
    region,
    -- Année de début du parcours : avec student_key, elle forme le grain de la table
    enrollment_year,
    -- Numéro de l'inscription de l'étudiant (1 = première) : permet de compter les étudiants distincts
    enrollment_rank,
    -- Nouveau ou Revenant, déduit du rang d'inscription
    student_status
-- ref() relie cette table au modèle intermédiaire et fixe l'ordre d'exécution dans dbt
from {{ ref('int_enrollments') }}