/*===========================================================
04_dimensions.sql
Builds the dimension tables for the project.
1. bi.DimDate: Calendar dimension table
2. bi.DimProduct: Product dimension table -> Derived from the bi.FactSales table
3. bi.DimStore: Store dimension table -> Derived from the bi.FactSales table
4. Primary keys are created for each dimension table.
Note:
- The bi.FactSales table is created in 03_unpivot_fact_sales.sql file.
- The files calendar.csv and sell_prices.csv need to be imported into the database with SSMS import wizard before executing this file.
============================================================*/

USE Personal_Project;
GO

/*===========================================================
1. Calendar dimension table (bi.Date)
The Import Wizard loads the calendar.csv file with empty event fields as empty strings ('')
so we need to replace them with NULL values in the bi.Date table.
============================================================*/

UPDATE bi.DimDate
SET event_name_1 = NULLIF(event_name_1,''), 
    event_type_1 = NULLIF(event_type_1,''),
    event_name_2 = NULLIF(event_name_2,''),
    event_type_2 = NULLIF(event_type_2,'')

/*===========================================================
2 & 3. DimProduct and DimStore dimension tables
Built from the bi.FactSales table. With Select Distinct we get the unique values for each dimension table.
============================================================*/

--*DimProduct

SELECT DISTINCT --Only Uniques

    item_id, -- PK will be used to connect to the Fact table in Power BI
    dept_id,
    cat_id

INTO bi.DimProduct
FROM bi.FactSales
GO

--*DimStore

SELECT DISTINCT

    store_id, --PK will be used to connect to the Fact table in Power BI
    state_id

INTO bi.DimStore
FROM bi.FactSales
GO

/* Validation of the data loaded into the Dimension tables
DimStore: 10 rows expected (10 unique stores)
DimProduct: 3049 rows expected (3049 unique products)*/

SELECT COUNT (*) AS ProductCount FROM bi.DimProduct 
SELECT COUNT(*) AS StoreCount FROM bi.DimStore 
GO 

/*===========================================================
4. Primary keys for the dimension tables
The PK is created for each dimension table to ensure that each row can be uniquely identified.
============================================================*/

ALTER TABLE bi.DimProduct ALTER COLUMN item_id VARCHAR(40) NOT NULL -- A PK column cannot accept NULL values.
ALTER TABLE bi.DimProduct ADD CONSTRAINT PK_DimProduct PRIMARY KEY (item_id)
GO

ALTER TABLE bi.DimStore ALTER COLUMN store_id VARCHAR(10) NOT NULL 
ALTER TABLE bi.DimStore ADD CONSTRAINT PK_DimStore PRIMARY KEY (store_id)
GO

ALTER TABLE bi.Date ALTER COLUMN day_id VARCHAR(10) NOT NULL 
ALTER TABLE bi.Date ADD CONSTRAINT PK_DimDate PRIMARY KEY (day_id)
GO