# DAX Measures 

All 52 DAX measures live in a dedicated table called `_Measure`, grouped in display folders. The model also includes one what-if parameter (`Growth Rate`) and two DAX calculated columns. 

> [!IMPORTANT]
> This document is only a summary. Every measure in the `.pbix` file includes detailed comments explaining how it works.
> To fully understand the measures, read the comments in Power BI. 

## Base Measures

|          Measure             |    What it does   |      
|------------------------------|-------------------| 
| `Total Revenue` |    `SUM` of `FactSales[revenue]`   |
|      `Total Units`       |  `SUM` of `FactSales[units_sold]`   |
|       `AVG Selling Price`         | Revenue divided by units        | 
|       `Availability`         | Rows where `available = 1` (product-store-days on sale)         | 
|       `Days With Sale`         | Rows with at least one unit sold         | 
|       `Sell-through %`         | `Days With Sale` / `Availability`: how often an available product actually sold        | 
|       `Selling Products`         | Distinct products with at least one unit sold        | 
|       `AVG Daily Revenue`         | Revenue divided by `Distinct Days`       | 

## Year-over-year pattern

Almost every card follows the same measure construction pattern: `... PY` (prior year), `... YoY %` and a `... Label` that formats the result as text with an arrow icon "(▲ / ▼)".

This dataset is a closed one, with the sales ending on May 22, 2016 so comparing 2016 with 2015 would be unfair because the model will be comparing almost 5 months of data against a full year. 

In order to avoid this unfairness when 2016 is selected, the PY measures compare against the same window in 2015 (Jan 1 to May 22), for every other year they use `SAMEPERIODLASTYEAR`:

```dax
Revenue PY = 
IF(
    SELECTEDVALUE(DimDate[year]) = 2016, 
    CALCULATE(
        [Total Revenue],
        DATESBETWEEN(DimDate[date], DATE(2015,1,1), DATE(2015,5,22)), 
        REMOVEFILTERS(DimDate[year]) 
    ),
     CALCULATE([Total Revenue], SAMEPERIODLASTYEAR(DimDate[date]))
)
```

`Sell-through YoY %` is the exception, this measure is already a rate so the comparison is a subtraction. (`Current - PY`)

## SNAP Analysis 

`Is SNAP Day` (Calculated column in `FactSales`) flags whether each row falls on a SNAP day for the store's state.

`AVG Daily SNAP Revenue` and `AVG Daily NON SNAP Revenue` divide revenue by the number of store-day combinations (`Store/Days Combinations`), so both groups are compared per store, per day.
`SNAP Day Revenue Lift %` is the relative difference between both averages (How much more a SNAP day earns compared with a NON SNAP day). 

## Regional Impact

| Measure | What it does |
|---------|--------------|
| `Top Store Rev` | Revenue of the best selling store | 
| `Top Store Share` | Share of the total revenue that comes from the top store | 
| `State Rev Spread` | The gap between the best and the worst state as share of revenue. (Blank when there is only one state selected) |

## Forecast (28 days)

Sales end on May 22, 2016 and the forecast covers the next 28 days. Each forecast day takes the average revenue of the same weekday 4, 5, 6 and 7 weeks back. Using these weeks guarantees that even the last forecast day is based on real data.

| Measure | What it does |
|---------|--------------|
| `Revenue Seasonal Avg` | The forecast value: average of the same weekday 4 to 7 weeks back | 
| `Rev Forecast High` / `Low` | Highest and Lowest of those 4 weeks used to build the confidence band | 
| `Revenue Naive` | Benchmark: the same day 4 weeks back | 
| `Revenue Forecast Line` | Draws the forecast line in the visual |
| `28 Day Forecast` | Total revenue expected over the 28 days | 
| `28-Day Real PY` | Real revenue of the same 28 days one year earlier | 
| `28D Forecast YoY %` | Forecast vs the same period last year |
| `Revenue Forecast What if` | `28 Day Forecast` adjusted by the `Growth Rate` parameter | 

## Calculated columns and Power Query

| Column | Table | Built with | Purpose |
|--------|--------------|------------|---------|
| `Is SNAP Day` | `FactSales` | DAX | SNAP flag per store's state and day |
| `Week Start` | `DimDate` | DAX | First date of each Walmart week (`wm_yr_wk`), used for weekly charts |
| `Store Name` | `DimStore` | Power Query | Readable store label for visuals (`CA_1` to `CA 1`) | 