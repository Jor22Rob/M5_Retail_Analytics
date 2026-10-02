/* =======================================================================
01_setup.sql
Creates the project database and the 2 schemas for the project.
- .pre: raw/staging tables that stay in SQL Server
- .bi: transformed tables that will be uploaded to Power BI 

Note: 
- sales_train_evaluation.csv file will be loaded with BULK INSERT in 02_load_raw_sales.sql file
- calendar.csv and sell prives.csv files will be loaded into the database with SSMS import wizard.
    calendar.csv -> bi.DimDate table
    sell_prices.csv -> pre.Prices table
The files imported with the wizard should be loaded after this query and before the 04_dimensions.sql file is executed.
======================================================================= */

CREATE DATABASE Personal_Project; -- *Creates the database named "Personal_Project"
GO -- ? Signals the end of a batch

ALTER DATABASE Personal_Project SET COMPATIBILITY_LEVEL = 170; 
-- * Sets the compatibility level to SQL Server 2025
GO

/*We set the compatibility level of the database to SQL Server 2025 to optimize the performance
and ensure that we can use the latest features and improvements available in SQL Server 2025. */

USE Personal_Project;
GO

/* =======================================================================
Schemas
======================================================================= */

CREATE SCHEMA pre; -- *Raw Data tables that will stay in SQL  
GO

CREATE SCHEMA bi; --* Transdormed data tables that will be used for analysis and reporting in Power BI
GO
