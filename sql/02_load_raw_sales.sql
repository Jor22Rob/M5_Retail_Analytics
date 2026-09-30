/* =======================================================================
02_load_raw_sales.sql
Creation of pre.RawSales table that will be used to load the data as text.
The file that will be loaded is "sales_train_evaluation.csv" (M5 dataset, Wide format) into the single column table prepared previously 
then a row identifier is added. 
The file is loaded like this because its 1947 columns exceed SQL Server's limit of 1024 columns per table.
======================================================================= */

USE Personal_Project; -- *Selects the database to be used for the following operations
GO 

/* =======================================================================
pre.RawSales Table
======================================================================= */

CREATE TABLE pre.RawSales
(
    line VARCHAR(MAX) NULL 
    /* One column to store the entire line of text from the CSV file, the column will accept NULL values.
    VARCHAR(MAX) is used to avoid size limitations. */
);
GO 

/* =======================================================================
Load of the CSV file into pre.RawSales table
======================================================================= */

BULK INSERT pre.RawSales -- *Loads the data from the file sales_train_evaluation.csv into the pre-table
FROM 'C:\path\to\sales_train_evaluation.csv' -- Replace this line with the actual path to the CSV file on your system.
WITH
(
    FIRSTROW = 2, -- Starts reading from the second row of the CSV file, skipping the header row.
    
    FIELDTERMINATOR = '|', -- Use this character as the field delimiter in the CSV file. 
    --This character is used as the delimiter to ensure that the full rows land in the column because the file is comma separated.
    
    ROWTERMINATOR = '0x0a', -- Line jumps to the next line after reading a row of data.

    CODEPAGE = '65001' -- Use UTF-8 
)
 /*This code loads the data from the specified CSV file into the pre.RawSales table, starting from the second row, using "|" as 
the field delimiter and "0x0a" as the row terminator(Is the hex code for "\n", is written like this to avoid being interpreted as a Windows line ending)
and the data is interpreted as UTF-8 encoded text. */
GO


--  Validation of the data loaded into the pre-table 

SELECT COUNT(*)  AS rows_loaded -- The number of rows loaded into the table.
FROM pre.RawSales 
-- Results should match the number of rows in the original CSV file, excluding the header. 30490 rows are expected.

/* =======================================================================
Row identifier
Add line_id column to pre.RawSales table and populate it with unique values
In order to be able to identify each row, this will be fundamental to transform the data and create the fact table.
(Executed after the load of the data into pre.RawSales)
======================================================================= */

ALTER TABLE pre.RawSales
ADD line_id INT IDENTITY(1,1) NOT NULL; 
GO
/* 
1. Add a new column called line_id with an auto-incrementing integer value starting from 1.
2. We don't mark it as primary key to avoid performance issues.
3. NOT NULL ensures that every row will have a value for line_id.
4. This column will serve as a unique identifier for each row in the pre.RawSales table.
*/

--line_id validation expecting 30490 unique values 
SELECT
COUNT(*) AS rows_count, 
COUNT(DISTINCT line_id) AS id_count
FROM pre.RawSales;

