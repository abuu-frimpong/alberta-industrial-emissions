-- ============================================================
-- Project 1: Canadian Industrial Emissions (GHGRP)
-- Script 01: Build the clean table from the raw import
-- Database: ghgrp.db (SQLite, DB Browser for SQLite)
-- Source: PDGES-GHGRP-GHGEmissionsGES-2004-Present.csv,
--         imported as raw_emissions_by_gas (never edited)
-- ============================================================

-- Delete the clean table if it exists, so this script can be rerun.
-- Never write this line for raw_emissions_by_gas.
DROP TABLE IF EXISTS emissions;

-- Copy only the columns needed, with short snake_case names.
-- Public contact names, emails and phone numbers are left out on purpose.
CREATE TABLE emissions AS
SELECT
    "GHGRP ID No. / No d'identification du PDGES" AS ghgrp_id,
    "Reference Year / Année de référence" AS year,
    "Facility Name / Nom de l'installation" AS facility_name,
    "Facility City or District or Municipality / Ville ou District ou Municipalité de l'installation" AS city,
    "Facility Province or Territory / Province ou territoire de l'installation" AS province,
    "Latitude" AS latitude,
    "Longitude" AS longitude,
    "Facility NAICS Code / Code SCIAN de l'installation" AS naics_code,
    "English Facility NAICS Code Description / Description du code SCIAN de l'installation en anglais" AS naics_description,
    "Reporting Company Legal Name / Dénomination sociale de la société déclarante" AS company_name,
    "CO2 (tonnes)" AS co2_t,
    "CH4 (tonnes CO2e / tonnes éq. CO2)" AS ch4_co2e,
    "N2O (tonnes CO2e / tonnes éq. CO2)" AS n2o_co2e,
    "HFC Total (tonnes CO2e / tonnes éq. CO2)" AS hfc_co2e,
    "PFC Total (tonnes CO2e / tonnes éq. CO2)" AS pfc_co2e,
    "SF6 (tonnes CO2e / tonnes éq. CO2)" AS sf6_co2e,
    "CO2 from biomass combustion (tonnes) / CO2 issu de la combustion de biomasse (tonnes)" AS co2_biomass_t,
    "Total Emissions (tonnes CO2e) / Émissions totales (tonnes éq. CO2) - excl. CO2bio" AS total_co2e
FROM raw_emissions_by_gas;

-- Fix: Fibrek SENC (G10263) has no province in 2011.
-- Its records for the other 20 years all place it in Quebec.
UPDATE emissions
SET province = 'Quebec'
WHERE ghgrp_id = 'G10263' AND year = 2011 AND province IS NULL;

-- ------------------------------------------------------------
-- Reconciliation checks: run after the script.
-- Expected: 20,685 rows and 291.7 Mt for 2024.
-- ------------------------------------------------------------
SELECT COUNT(*) FROM emissions;

SELECT ROUND(SUM(total_co2e) / 1000000.0, 1) AS total_mt
FROM emissions
WHERE year = 2024;

-- Remember: press Ctrl+S (Write Changes) after running.
