-- ============================================================
-- Project 1: Canadian Industrial Emissions (GHGRP)
-- Script 04: Export views for Power BI and QGIS
-- Run all of it, then press Ctrl+S (Write Changes) straight away.
-- A view is only saved in the database after Write Changes.
-- ============================================================

-- Power BI export: every row, with the sector, the 50 kt label and a coordinates flag.
-- City (inconsistent spellings) and biomass CO2 (never added to totals) are left out on purpose.
DROP VIEW IF EXISTS powerbi_export;

CREATE VIEW powerbi_export AS
SELECT ghgrp_id, year, facility_name, province, latitude, longitude,
       naics_code, naics_description, company_name, sector,
       co2_t, ch4_co2e, n2o_co2e, hfc_co2e, pfc_co2e, sf6_co2e, total_co2e,
       CASE WHEN total_co2e >= 50000 THEN '50 kt or more' ELSE 'Under 50 kt' END AS size_group,
       CASE WHEN latitude IS NULL OR latitude = '' THEN 'No' ELSE 'Yes' END AS has_coordinates
FROM emissions_with_sector;

-- QGIS export: 2024 facilities with coordinates, emissions in kilotonnes.
DROP VIEW IF EXISTS map_2024;

CREATE VIEW map_2024 AS
SELECT ghgrp_id, facility_name, province, sector, latitude, longitude,
       ROUND(total_co2e / 1000.0, 1) AS kt_co2e
FROM emissions_with_sector
WHERE year = 2024
  AND latitude IS NOT NULL AND latitude <> '';

-- Checks. Expected: 1,879 rows and 291.7 Mt; then 1,863 facilities and 281.7 Mt.
SELECT COUNT(*), ROUND(SUM(total_co2e) / 1000000.0, 1) FROM powerbi_export WHERE year = 2024;

SELECT COUNT(*) AS facilities, ROUND(SUM(kt_co2e) / 1000.0, 1) AS mt_co2e FROM map_2024;

-- Largest facilities in 2024.
SELECT facility_name, province, sector, kt_co2e
FROM map_2024
ORDER BY kt_co2e DESC
LIMIT 5;

-- Largest power plants in 2024. Result: Saskatchewan's Poplar River, Boundary Dam
-- and Shand together emitted 7.4 Mt; Poplar River and Boundary Dam are coal plants.
SELECT facility_name, province, kt_co2e
FROM map_2024
WHERE sector = 'Utilities'
ORDER BY kt_co2e DESC
LIMIT 10;
