/*===============================================
05_prices_and_revenue.sql
Brings the price of each product into bi.FactSales table and:
1. Index on pre.Prices to optimize the join with bi.FactSales table.
2.available: flag to separate "no sales" from "product not on sale yet" situations.
3.sell price per row joined through bi.DimDate (weekly granularity).
4.revenue as a persistent column to avoid calculating it on the fly in Power BI.
5.Validations
=================================================*/

USE Personal_Project;
GO

/* =======================================================
1.Index on pre.Prices table
It's built on the same 3 columns that will be used to join with bi.FactSales table.
==========================================================*/

CREATE CLUSTERED INDEX idx_SellPrices 
ON pre.Prices (
    store_id,
    item_id,
    wm_yr_wk)
GO

/* =======================================================
2. available and prices columns are created in bi.FactSales
A 0 in units_sold column can mean either that the product had no sales or that the product was not on sale yet
in that store. This flag tells these situations apart.
==========================================================*/

ALTER TABLE bi.FactSales
ADD available BIT NOT NULL DEFAULT 0, -- 1 = product on sale, 0 = not on sale. No NULLS to avoid confusion
    prices DECIMAL (8,2) NULL; -- Sell price. NULL when the product wasn't on sale that week.
GO

/* =======================================================
3. Bring the price of each product into bi.FactSales table and mark availability
Prices are weekly and sales daily, so we need to join bi.FactSales with bi.DimDate to get the week of each sale,
this translates each day_id into its Walmart week (wm_yr_wk) to be able to join with pre.Prices table.
==========================================================*/

UPDATE f
SET f.available = CASE WHEN p.sell_price IS NOT NULL THEN 1 ELSE 0 END, --Price found = 1(available), Price not found = 0
    f.prices = p.sell_price
FROM bi.FactSales AS f
JOIN bi.DimDate AS d
    ON d.day_id = f.day_id -- Join on day_id to connect Prices (week granularity) to FactSales(day granularity) 
LEFT JOIN pre.Prices AS p -- LEFT JOIN in case there is no price data it still brings it as a NULL
    ON p.store_id = f.store_id
    AND p.item_id = f.item_id
    AND p.wm_yr_wk = d.wm_yr_wk 
GO
-- A price belongs to a specific item in a specific store in a specific week, so the three keys together return exactly one price per row.

/* =======================================================
4.Revenue column
Calculated in SQL instead of Power BI to reduce the amount of calculations done in Power BI and improve performance.
PERSISTED stores the result physically in the table, so it doesn't need to be recalculated every time it's queried.
When there is no price is NULL so the revenue is also NULL, this doesn't affect the total revenue calculation.
==========================================================*/

ALTER TABLE bi.FactSales
ADD revenue AS (units_sold * prices) PERSISTED;
GO

/* =======================================================
5.Validations
01. A product that was not on sale should not have units sold
02. Visual check of the series ordened by the real day 
==========================================================*/

SELECT COUNT(*) AS Unavailable_sales
FROM bi.FactSales
WHERE available = 0 AND units_sold > 0

SELECT TOP 15 item_id, store_id, day_id, units_sold, available, prices, revenue
FROM bi.FactSales
WHERE item_id = 'HOBBIES_1_001' AND store_id = 'CA_1'
ORDER BY CAST(SUBSTRING(day_id,3,5) AS INT)
 -- Order by the real day (d_1, d_2, d_3...) instead of the string order (d_1, d_10, d_11...)
