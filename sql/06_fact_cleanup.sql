/*===============================================
06_fact_cleanup.sql
Final cleanup of bi.FactSales table before uploading to Power Bi.
Drops the columns that are not needed and that now exist in the dimension tables.
Note: 
'DROP' is a irreversible operation, so make sure to confirm that the columns already exist in the dimension tables before executing this file.
=================================================*/

USE Personal_Project;
GO

/*===============================================
Drop the columns
=================================================*/

ALTER TABLE bi.FactSales DROP COLUMN dept_id; -- Now in DimProduct
ALTER TABLE bi.FactSales DROP COLUMN cat_id; -- Now in DimProduct
ALTER TABLE bi.FactSales DROP COLUMN state_id; -- Now in DimStore

/*===============================================
Validations
=================================================*/

--Visual confirmation of the columns dropped
SELECT TOP 10 * FROM bi.FactSales
GO  

--Dropping columns does not the total number of rows: 59,181,090 rows expected
SELECT COUNT(*) AS total_rows FROM bi.FactSales
GO
