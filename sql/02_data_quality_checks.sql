-- ============================================================
-- Project 1: Canadian Industrial Emissions (GHGRP)
-- Script 02: Data quality checks on the clean table
-- Run each query on its own: highlight it, then Ctrl+Return.
-- ============================================================

-- Check 1: Missing coordinates by year, as a count and a share of emissions.
-- CASE WHEN works like IF in Excel. Blanks can be NULL or empty text, so check both.
-- Result: 2024 has 16 facilities missing, 3.41% of emissions.
SELECT year,
       SUM(CASE WHEN latitude IS NULL OR latitude = '' THEN 1 ELSE 0 END) AS missing_facilities,
       ROUND(100.0 * SUM(CASE WHEN latitude IS NULL OR latitude = '' THEN total_co2e ELSE 0 END)
             / SUM(total_co2e), 2) AS pct_emissions_missing
FROM emissions
GROUP BY year
ORDER BY year;

-- Check 1b: Which 2024 facilities lack coordinates, largest first.
-- The brackets around the OR keep the year filter applied to both conditions.
-- Result: 16 natural gas pipelines and distribution systems.
SELECT ghgrp_id, facility_name, city, province, naics_description,
       ROUND(total_co2e / 1000.0, 1) AS kt_co2e
FROM emissions
WHERE year = 2024 AND (latitude IS NULL OR latitude = '')
ORDER BY total_co2e DESC;

-- Check 2: Do the six gases add up to the total?
-- COALESCE turns blanks into 0. Biomass is left out because it is excluded from totals.
-- Result: 0 mismatches.
SELECT COUNT(*) AS mismatches
FROM emissions
WHERE ABS(total_co2e - (COALESCE(co2_t, 0) + COALESCE(ch4_co2e, 0) + COALESCE(n2o_co2e, 0)
                       + COALESCE(hfc_co2e, 0) + COALESCE(pfc_co2e, 0) + COALESCE(sf6_co2e, 0))) > 1;

-- Check 2b: Are any totals blank? (Check 2 would silently skip them.)
-- Result: 0.
SELECT COUNT(*) AS blank_totals
FROM emissions
WHERE total_co2e IS NULL OR total_co2e = '';

-- Check 3: Province spellings. Expect 13 rows, one spelling each.
-- Counts are facility-years, not facilities.
-- Result before fix: 13 provinces plus 1 NULL. After fix: 13, Quebec = 2,503.
SELECT province, COUNT(*) AS rows
FROM emissions
GROUP BY province
ORDER BY rows DESC;

-- Check 3b: Find the record with no province.
-- Result: G10263, Fibrek SENC, 2011, 85.1 kt.
SELECT ghgrp_id, year, facility_name, city, latitude, longitude,
       ROUND(total_co2e / 1000.0, 1) AS kt_co2e
FROM emissions
WHERE province IS NULL;

-- Check 3c: That facility's full history. Search by ID, because names change.
-- Result: Quebec in all other 20 years (SFK Pâte to 2010, Fibrek SENC from 2011).
SELECT ghgrp_id, year, facility_name, city, province
FROM emissions
WHERE ghgrp_id = 'G10263'
ORDER BY year;
