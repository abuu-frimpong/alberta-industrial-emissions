-- ============================================================
-- Project 1: Canadian Industrial Emissions (GHGRP)
-- Script 03: Analysis (Steps 5 and 6)
-- Run each query on its own: highlight it, then Ctrl+Return.
-- ============================================================

-- Step 5a: Check the NAICS code format before cutting digits off it.
-- Result: 6-digit integers, like 322111.
SELECT naics_code, typeof(naics_code) AS code_type, naics_description
FROM emissions
WHERE year = 2024
LIMIT 10;

-- Step 5b: 2024 emissions by sector, from the first two NAICS digits.
-- CAST turns the number into text so SUBSTR can take the first 2 characters.
-- The subquery in brackets calculates the 2024 total once, for the percentages.
-- Result: 43.1%, 28.8%, 20.2%, matching ECCC's 43%, 29%, 20%.
SELECT
    CASE SUBSTR(CAST(naics_code AS TEXT), 1, 2)
        WHEN '21' THEN 'Mining, quarrying, oil and gas'
        WHEN '22' THEN 'Utilities'
        WHEN '31' THEN 'Manufacturing'
        WHEN '32' THEN 'Manufacturing'
        WHEN '33' THEN 'Manufacturing'
        ELSE 'Other'
    END AS sector,
    COUNT(*) AS facilities,
    ROUND(SUM(total_co2e) / 1000000.0, 1) AS mt_co2e,
    ROUND(100.0 * SUM(total_co2e)
          / (SELECT SUM(total_co2e) FROM emissions WHERE year = 2024), 1) AS pct_of_total
FROM emissions
WHERE year = 2024
GROUP BY sector
ORDER BY mt_co2e DESC;

-- Step 5c: What is inside "Other".
-- NOT IN skips NULLs silently, so OR naics_code IS NULL keeps any facility with no code.
-- Result: pipelines (48) 12.1 Mt, waste (56) 8.6 Mt. No NULL codes.
SELECT SUBSTR(CAST(naics_code AS TEXT), 1, 2) AS code2,
       COUNT(*) AS facilities,
       ROUND(SUM(total_co2e) / 1000000.0, 1) AS mt_co2e,
       MIN(naics_description) AS example_industry
FROM emissions
WHERE year = 2024
  AND (SUBSTR(CAST(naics_code AS TEXT), 1, 2) NOT IN ('21', '22', '31', '32', '33')
       OR naics_code IS NULL)
GROUP BY code2
ORDER BY mt_co2e DESC;

-- Step 5d: Save the sector grouping as a view (a saved query that acts like a table).
-- It stores no data, so it stays correct if the emissions table is rebuilt.
DROP VIEW IF EXISTS emissions_with_sector;

CREATE VIEW emissions_with_sector AS
SELECT *,
    CASE SUBSTR(CAST(naics_code AS TEXT), 1, 2)
        WHEN '21' THEN 'Mining, quarrying, oil and gas'
        WHEN '22' THEN 'Utilities'
        WHEN '31' THEN 'Manufacturing'
        WHEN '32' THEN 'Manufacturing'
        WHEN '33' THEN 'Manufacturing'
        WHEN '48' THEN 'Pipeline transportation'
        WHEN '56' THEN 'Waste management'
        ELSE 'Other'
    END AS sector
FROM emissions;

-- Check the view: six sectors, 1,879 facilities, about 291.6 Mt in 2024.
SELECT sector, COUNT(*) AS facilities,
       ROUND(SUM(total_co2e) / 1000000.0, 1) AS mt_co2e
FROM emissions_with_sector
WHERE year = 2024
GROUP BY sector
ORDER BY mt_co2e DESC;

-- Step 5e: 2024 emissions by province.
-- Result: Alberta 152.7 Mt (52.4%), Ontario 51.0 Mt (17.5%).
SELECT province,
       COUNT(*) AS facilities,
       ROUND(SUM(total_co2e) / 1000000.0, 1) AS mt_co2e,
       ROUND(100.0 * SUM(total_co2e)
             / (SELECT SUM(total_co2e) FROM emissions WHERE year = 2024), 1) AS pct_of_total
FROM emissions
WHERE year = 2024
GROUP BY province
ORDER BY mt_co2e DESC;

-- Step 6a: Alberta's naive trend, all facilities.
-- Result: 2016 to 2017 jumps from 203 to 661 facilities and 141.1 to 159.1 Mt.
SELECT year,
       COUNT(*) AS facilities,
       ROUND(SUM(total_co2e) / 1000000.0, 1) AS mt_co2e
FROM emissions
WHERE province = 'Alberta'
GROUP BY year
ORDER BY year;

-- Step 6b: Alberta's consistent trend, facilities of 50 kt (50,000 tonnes) or more, from 2009.
-- 2009 is the first year every facility of 50 kt or more had to report.
-- Result: 118.2 Mt (2009) to 141.6 Mt (2024). Of the 2017 jump, 9.1 Mt came from facilities under 50 kt.
SELECT year,
       SUM(CASE WHEN total_co2e >= 50000 THEN 1 ELSE 0 END) AS facilities_50kt,
       ROUND(SUM(CASE WHEN total_co2e >= 50000 THEN total_co2e ELSE 0 END) / 1000000.0, 1) AS mt_50kt,
       COUNT(*) AS all_facilities,
       ROUND(SUM(total_co2e) / 1000000.0, 1) AS mt_all
FROM emissions
WHERE province = 'Alberta' AND year >= 2009
GROUP BY year
ORDER BY year;

-- Step 6c: Alberta's consistent trend by sector, as a pivot (one column per sector).
-- Check: each row adds up to that year's mt_50kt from 6b.
-- Result: oil, gas and mining 50.1 to 91.3 Mt; utilities 48.1 to 22.3 Mt.
SELECT year,
       ROUND(SUM(CASE WHEN sector = 'Mining, quarrying, oil and gas' THEN total_co2e ELSE 0 END) / 1000000.0, 1) AS oil_gas_mining,
       ROUND(SUM(CASE WHEN sector = 'Utilities' THEN total_co2e ELSE 0 END) / 1000000.0, 1) AS utilities,
       ROUND(SUM(CASE WHEN sector = 'Manufacturing' THEN total_co2e ELSE 0 END) / 1000000.0, 1) AS manufacturing,
       ROUND(SUM(CASE WHEN sector = 'Pipeline transportation' THEN total_co2e ELSE 0 END) / 1000000.0, 1) AS pipelines,
       ROUND(SUM(CASE WHEN sector IN ('Waste management', 'Other') THEN total_co2e ELSE 0 END) / 1000000.0, 1) AS other
FROM emissions_with_sector
WHERE province = 'Alberta' AND year >= 2009 AND total_co2e >= 50000
GROUP BY year
ORDER BY year;

-- Step 6d: Alberta utilities, 15 largest emitters in 2017, with 2024 for comparison.
-- Result: five plants (Sundance, Keephills, Genesee, Sheerness, Battle River) cut 28.3 Mt.
-- Note: sorting by 2017 hides plants that did not exist in 2017.
SELECT ghgrp_id,
       MAX(facility_name) AS facility_name,
       ROUND(SUM(CASE WHEN year = 2017 THEN total_co2e ELSE 0 END) / 1000000.0, 2) AS mt_2017,
       ROUND(SUM(CASE WHEN year = 2024 THEN total_co2e ELSE 0 END) / 1000000.0, 2) AS mt_2024
FROM emissions_with_sector
WHERE province = 'Alberta' AND sector = 'Utilities' AND year IN (2017, 2024)
GROUP BY ghgrp_id
ORDER BY mt_2017 DESC
LIMIT 15;

-- Step 6e: Alberta utilities sorted by change from 2017 to 2024, largest increase first.
-- Result: top 10 grew by 4.18 Mt; Cascade, Milner M2 and Heartland are new since 2017.
SELECT ghgrp_id,
       MAX(facility_name) AS facility_name,
       ROUND(SUM(CASE WHEN year = 2017 THEN total_co2e ELSE 0 END) / 1000000.0, 2) AS mt_2017,
       ROUND(SUM(CASE WHEN year = 2024 THEN total_co2e ELSE 0 END) / 1000000.0, 2) AS mt_2024,
       ROUND((SUM(CASE WHEN year = 2024 THEN total_co2e ELSE 0 END)
            - SUM(CASE WHEN year = 2017 THEN total_co2e ELSE 0 END)) / 1000000.0, 2) AS change_mt
FROM emissions_with_sector
WHERE province = 'Alberta' AND sector = 'Utilities' AND year IN (2017, 2024)
GROUP BY ghgrp_id
ORDER BY change_mt DESC
LIMIT 10;
