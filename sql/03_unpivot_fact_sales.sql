/* =======================================================================
03_unpivot_fact_sales.sql
Transformation of the table pre.RawSales (one text line per item-store combination) into the fact table
bi.FactSales(one row per item-store-day combination).
Steps:
1.Unpivot every line into multiple rows (line_id, ordinal, value) with STRING_SPLIT.
2.Rebuild the 5 columns into a temporary table.
3.Create the bi.FactSales table and load the daily values from the pre.FactSales joined to the IDs in the temporary table.
4.Validate the data loaded.
5.Create the clustered index on the bi.FactSales table to optimize query performance.
======================================================================= */

USE Personal_Project;
GO

/* =======================================================================
1.Unpivot of pre.RawSales table 
======================================================================= */

SELECT 

    pr.line_id,     -- This column will be used to link the pre.FactSales table with the pre.RawSales.
    c.ordinal,      -- Position value given by STRING_SPLIT.
    c.value         -- Value given by STRING_SPLIT.
INTO pre.FactSales  -- Creates a new table and inserts the results of the SELECT statement into it.

FROM pre.RawSales as pr
CROSS APPLY STRING_SPLIT(pr.line, ',', 1) as c; 
/* 
CROSS APPLY runs STRING_SPLIT on every row of pre.RawSales, creating a new row for each value in the line column.
STRING_SPLIT is used to split the line column into multiple rows based on the "," as the delimiter.
The third parameter of STRING_SPLIT is set to 1 to include the position of each value in the original data, which is returned as "ordinal".
Value is also given by STRING_SPLIT and it is the value of each split. */
GO

/* We know that we have 30490 lines in the pre.RawSales table and we have 1947 (6 ID columns and 1941 daily values) values 
so the total should be 30490*1947 = 59,364,030 rows in the pre.FactSales table. 

Quick check: */
SELECT COUNT(*) AS total_rows_unpivoted
FROM pre.FactSales;

/* =======================================================================
Creation of a temporary table to clean and transform the IDs.
Notes:
1. This query creates a temporary table to rebuild the 5 IDs into one row per line using their position.
======================================================================= */

SELECT 
    p.line_id, -- The line key
    MAX(CASE WHEN p.ordinal = 2 THEN p.value END) AS item_id, 
    MAX(CASE WHEN p.ordinal = 3 THEN p.value END) AS dept_id,
    MAX(CASE WHEN p.ordinal = 4 THEN p.value END) AS cat_id,
    MAX(CASE WHEN p.ordinal = 5 THEN p.value END) AS store_id,
    MAX(CASE WHEN p.ordinal = 6 THEN p.value END) AS state_id

INTO #TempHeaders -- Creates a temporary table to store the cleaned id values.
FROM pre.FactSales AS p
WHERE p.ordinal BETWEEN 2 AND 6 -- We only want the headers, so we filter by their ordinal position.
GROUP BY p.line_id; -- We group by line_id to get one row per line with the cleaned headers.
GO

/* CASE gets the value at each ordinal position and MAX collapses the rows of each line_id into a single row (A manual pivot)
Position 1 is skipped because it holds the original M5 "id" column */

SELECT COUNT(*) AS headers_rows FROM #TempHeaders; -- 30490 rows are expected. 
SELECT TOP 10 * FROM #TempHeaders; -- Quick check of the temporary table with the cleaned headers.


/* =======================================================================
Creation of the bi.FactSales table
Before finishing the transformation process, we need a table where we will load the unpivoted data from the pre.FactSales table. 
Notes:
1. This bi.FactSales table is where the unpivot will be loaded.
2. The fact table will contain columns that will be used to create Dimension tables.
3. These columns will be removed after completing the transformation process because they will be in the Dimension tables.
4. This table will be complemented with more data from other files later on.
======================================================================= */ 

CREATE TABLE bi.FactSales  --* Creation of the fact table
(
    item_id VARCHAR(40) NOT NULL,   -- Product  (DimProduct)
    dept_id VARCHAR(20) NOT NULL,   -- Department  (DimProduct) 
    cat_id VARCHAR(20) NOT NULL,    -- Category  (DimProduct)
    store_id VARCHAR(10) NOT NULL,  -- Store  (DimStore)
    state_id VARCHAR(5) NOT NULL,   -- State  (DimStore)
    day_id VARCHAR(10) NOT NULL,    -- Day  (DimDate)
    units_sold INT NOT NULL        -- Units Sold, units sold that day
);

GO 

INSERT INTO bi.FactSales (item_id, dept_id, cat_id, store_id, state_id, day_id, units_sold) --Where is gonna be loaded the data
SELECT 
-- What is getting loaded 
    h.item_id,
    h.dept_id,
    h.cat_id,
    h.store_id,
    h.state_id,
    'd_' + CAST(p.ordinal - 6 AS VARCHAR(10)) AS day_id,
--Positions 1 to 6 are the headers, so we subtract 6 from the ordinal to match the day_id format in the original data.
    CAST(p.value AS INT) AS units_sold
-- We cast the value as INT to be able to use it for calculations in Power BI, since it represents the units sold that day.

FROM pre.FactSales AS p
JOIN #TempHeaders AS h
ON h.line_id = p.line_id -- Join based on the line_id which is the same in both tables.
WHERE p.ordinal >= 7; -- We only want the values that correspond to the days.

/* =======================================================
Validation of the data loaded into the bi.FactSales table
==========================================================*/

-- Total rows: must be 30,490 lines * 1,941 days = 59,181,090
SELECT COUNT(*) AS total_rows FROM bi.FactSales;
GO

-- Every Store must have 1941 distinct days (The number of days in the original data) 
SELECT store_id, COUNT(DISTINCT day_id) AS dif_days
FROM bi.FactSales
GROUP BY store_id
GO

-- Sample to confirm the structure 
SELECT TOP 10 *
FROM bi.FactSales  
GO

/* =======================================================
Index Creation 
1. We create this index to help the table with future tasks that will be done.
2. Created on day_id, item_id, store_id because they will be used to make relationships and the Dim tables
==========================================================*/

CREATE CLUSTERED INDEX idx_FactSales 
ON bi.FactSales (
    day_id, 
    item_id, 
    store_id
)

GO