-- =============================================================================
-- Enterprise Survey 2020 - SQL Solutions
-- Dataset: annual-enterprise-survey-2020-financial-year-provisional.csv
-- Target DB: PostgreSQL
-- Author: Richardy Lobo' Sapan
-- =============================================================================
-- =============================================================================
-- First before jumping into the solutions, it is wise to understand what dataset is about. Below is the brief overview of our dataset
-- DATASET OVERVIEW
-- Source  : Annual Enterprise Survey 2020 - Financial Year (Provisional)
-- Origin  : Stats NZ (New Zealand Official Statistics)
-- =============================================================================
-- Now, lets understand the shape of the dataset. Can be done by doing some manuplation in excel
--
-- SHAPE
--   Rows    : 37,080
--   Columns : 10
--   Years   : 2013 - 2020 (8 years, 4,635 rows each)
--
--Lets analyze each column
--
-- COLUMNS
--   Year                        : Survey year (2013-2020)
--   Industry_aggregation_NZSIOC : Hierarchy level (Level 1, Level 3, Level 4)
--   Industry_code_NZSIOC        : Numeric industry code
--   Industry_name_NZSIOC        : Industry name (111 unique industries-DISTINCT values!)
--   Units                       : Dollars (millions) | Dollars | Percentage
--   Variable_code               : Short code for the variable (contoh: H01)
--   Variable_name               : Financial metric name (41 unique variables)
--   Variable_category           : Financial performance, Finacial position, and Financial ratios
--   Value                       : VARCHAR with comma-formatted numbers
--                                 Contoh '733,258'. important because that means query requires REPLACE + CAST (changing type)
--   Industry_code_ANZSIC06      : Secondary classification code
--
-- Next, lets check the data quality. we'll need to check whether it contains nulls, and gotta check the value type!!!
--
-- DATA QUALITY
--   Nulls   : None across all columns
--   Notable : Notice that value column is stored as string, not numeric.
--             All aggregations require CAST(REPLACE(Value, ',', '') AS NUMERIC)
--
-- Now, letss check values for each of the columns
--
-- KEY DISTINCT VALUES
--   Units (used in filters below):
--     - 'Dollars'            (2,032 rows)
--     - 'Dollars (millions)' (29,152 rows)
--     - 'Percentage'         (5,896 rows)
--
--   Industry_aggregation_NZSIOC:
--     - Level 1  : Broadest grouping  (4,472 rows)
--     - Level 3  : Mid-level grouping (12,312 rows)
--     - Level 4  : Most granular      (20,296 rows)
--
--   Variable_category:
--     - Financial performance (income, expenditure, surplus)
--     - Financial position    (assets, liabilities, equity)
--     - Financial ratios      (return on equity, current ratio, etc.)
-- =============================================================================

-- 
-- Now that we got the brief information about the dataset, we can proceed to create the sql queries, with the assumptions below
-- 
-- ASSUMPTIONS:
-- 1. The `Value` column is stored as VARCHAR with comma-formatted numbers
--    (contoh: '733,258'). All numeric operations require REPLACE + CAST
-- 2. "Units only Dollars" means WHERE Units = 'Dollars' (not 'Dollars (millions)')
-- 3. Problem 1 does not filter by unit, it returns all units for the 3 industries.
-- 4. Problem 2 "all industry aggregation" means GROUP BY Industry_aggregation_NZSIOC
--    (values: Level 1, Level 3, Level 4), not by individual industry names.
-- 5. Problem 3 "per level" refers to Industry_aggregation_NZSIOC column.
-- 6. Problem 5 "transposed format" = pivoted so ranks become rows and years become
--    columns, using conditional aggregation (CASE WHEN).
-- 7. Where problems ask for "total value", NULL/non-numeric Values are ignored.
--    In this dataset there are no nulls, but the CAST is still guarded!!!
-- 8. DENSE_RANK() is used over ROW_NUMBER() and RANK() for ranking in Problem 5.
-- 	ROW_NUMBER() is excluded as it breaks ties arbitrarily, producing non-deterministic
-- 	results when two variables share the same total value.
-- 	RANK() is excluded as it skips rank positions after a tie (e.g. 1, 1, 3),
-- 	which risks missing a rank position when filtering top/bottom 3.
-- 	DENSE_RANK() is chosen as it preserves consecutive rank positions (e.g. 1, 1, 2),
-- 	ensuring ranks 1 through 3 always exist regardless of ties.
-- =============================================================================


-- =============================================================================
-- Now, lets do the queries
-- 
-- 
-- PROBLEM 1
-- Generate value of "Total equity and liabilities"
-- from industry name "Mining", "Printing" and "Construction"
-- =============================================================================

SELECT
    Year,
    Industry_name_NZSIOC AS industry_name,
    Industry_aggregation_NZSIOC AS industry_level,
    Units,
    Variable_name,
    CAST(REPLACE(Value, ',', '') AS NUMERIC) AS value -- we need to change the type and remove comma
FROM
    enterprise_survey
WHERE
    Variable_name       = 'Total equity and liabilities'
    AND Industry_name_NZSIOC IN ('Mining', 'Printing', 'Construction') -- see assumptions, we dont filter for 3 industries
ORDER BY
    Industry_name_NZSIOC,
    Year;


-- =============================================================================
-- PROBLEM 2
-- Generate total value for all industry aggregation
-- based on each variable name and units only Dollars
-- =============================================================================

SELECT
    Industry_aggregation_NZSIOC AS industry_aggregation,
    Variable_name,
    Units,
    SUM(CAST(REPLACE(Value, ',', '') AS NUMERIC)) AS total_value -- change type and remove comma inside
FROM
    enterprise_survey
WHERE
    Units = 'Dollars' -- see assumptions, only dollars means units = Dollars
GROUP BY
    Industry_aggregation_NZSIOC,
    Variable_name,
    Units
ORDER BY
    Industry_aggregation_NZSIOC,
    Variable_name;


-- =============================================================================
-- PROBLEM 3
-- Generate total value based on per individual industry name,
-- per level and units only Dollars
-- =============================================================================

SELECT
    Industry_name_NZSIOC AS industry_name,
    Industry_aggregation_NZSIOC AS industry_level, -- see assumptions, per level means industry aggregation level
    Units,
    SUM(CAST(REPLACE(Value, ',', '') AS NUMERIC)) AS total_value -- change type and remove comma
FROM
    enterprise_survey
WHERE
    Units = 'Dollars'
GROUP BY
    Industry_name_NZSIOC,
    Industry_aggregation_NZSIOC
ORDER BY
    Industry_name_NZSIOC,
    Industry_aggregation_NZSIOC;


-- =============================================================================
-- PROBLEM 4
-- Generate summary of yearly total values
-- based on industry name and units only Dollars
-- =============================================================================

SELECT
    Year,
    Industry_name_NZSIOC AS industry_name,
    Units,
    SUM(CAST(REPLACE(Value, ',', '') AS NUMERIC)) AS yearly_total_value -- change type and remove comma
FROM
    enterprise_survey
WHERE
    Units = 'Dollars'
GROUP BY
    Year,
    Industry_name_NZSIOC
ORDER BY
    Industry_name_NZSIOC,
    Year;


-- =============================================================================
-- PROBLEM 5
-- Generate top 3 and bottom 3 variable name in transposed format
-- based on each year and units only Dollars
--
-- Approach:
--   Step 1 (cte_totals)  : sum value per year + variable_name
--   Step 2 (cte_ranked)  : rank each variable within its year,
--                          both descending (top) and ascending (bottom)
--   Step 3 (cte_filtered): keep only rank 1-3 from each direction
--   Step 4 (final)       : pivot years into columns using CASE WHEN
--
-- Note: years 2013-2020 are hard-coded in the pivot because PostgreSQL
-- does not support dynamic column names without PL/pgSQL or crosstab().
-- If the dataset gains new years, add matching CASE WHEN blocks.
-- =============================================================================

WITH cte_totals AS (
    -- Aggregate total value per year and variable name (Dollars only)
    SELECT
        Year,
        Variable_name,
        SUM(CAST(REPLACE(Value, ',', '') AS NUMERIC)) AS total_value -- change type and remove comma
    FROM
        enterprise_survey
    WHERE
        Units = 'Dollars'
    GROUP BY
        Year,
        Variable_name
),

cte_ranked AS (
    -- Rank variables within each year (top = highest value, bottom = lowest)
    SELECT
        Year,
        Variable_name,
        total_value,
        DENSE_RANK() OVER (PARTITION BY Year ORDER BY total_value DESC) AS rank_top, -- see assumptions on why we use DENSE_RANK()
        DENSE_RANK() OVER (PARTITION BY Year ORDER BY total_value ASC)    AS rank_bottom
    FROM
        cte_totals
),

cte_filtered AS (
    -- Keep top 3 and bottom 3, label them
    SELECT -- for top 3
        Year,
        Variable_name,
        total_value,
        'Top' AS category,
        rank_top AS rank
    FROM cte_ranked
    WHERE rank_top <= 3

    UNION ALL

    SELECT -- for bottom 3
        Year,
        Variable_name,
        total_value,
        'Bottom' AS category,
        rank_bottom AS rank
    FROM cte_ranked
    WHERE rank_bottom <= 3
)

-- Pivot: rows = category + rank, columns = each year
SELECT
    category,
    rank,

-- Variable name columns (var_YYYY) are kept alongside value columns (val_YYYY)
-- because rankings can shift across years as total values change over time.
-- A variable that ranks 1st in 2013 may not rank 1st in 2020, meaning
-- var_YYYY and val_YYYY are tightly coupled, each value column needs its own
-- corresponding variable name column to correctly identify which variable
-- earned that rank in that specific year.

    -- Variable name per year
    MAX(CASE WHEN Year = 2013 THEN Variable_name END)       AS var_2013,
    MAX(CASE WHEN Year = 2014 THEN Variable_name END)       AS var_2014,
    MAX(CASE WHEN Year = 2015 THEN Variable_name END)       AS var_2015,
    MAX(CASE WHEN Year = 2016 THEN Variable_name END)       AS var_2016,
    MAX(CASE WHEN Year = 2017 THEN Variable_name END)       AS var_2017,
    MAX(CASE WHEN Year = 2018 THEN Variable_name END)       AS var_2018,
    MAX(CASE WHEN Year = 2019 THEN Variable_name END)       AS var_2019,
    MAX(CASE WHEN Year = 2020 THEN Variable_name END)       AS var_2020,

    -- Total value per year
    MAX(CASE WHEN Year = 2013 THEN total_value END)         AS val_2013,
    MAX(CASE WHEN Year = 2014 THEN total_value END)         AS val_2014,
    MAX(CASE WHEN Year = 2015 THEN total_value END)         AS val_2015,
    MAX(CASE WHEN Year = 2016 THEN total_value END)         AS val_2016,
    MAX(CASE WHEN Year = 2017 THEN total_value END)         AS val_2017,
    MAX(CASE WHEN Year = 2018 THEN total_value END)         AS val_2018,
    MAX(CASE WHEN Year = 2019 THEN total_value END)         AS val_2019,
    MAX(CASE WHEN Year = 2020 THEN total_value END)         AS val_2020

FROM
    cte_filtered
GROUP BY
    category,
    rank
ORDER BY
    category DESC,  -- 'Top' before 'Bottom'
    rank ASC;
