# Design Decisions 

Key decisions made during the project including the reasons that led to them.

## 1. SNAP Day Revenue Lift %: a calculation error

**Note:** SNAP is a US government food assistance program. Its benefits are paid on specific days of each month and each state has its own dates.

**Problem:** During the creation of the SNAP measures the result obtained was that for 2016 SNAP days sell **4.15%** less, suggesting that SNAP days sell less than regular days. This result generated doubts so after reviewing the calculation the cause became clear. 

**Reason:** The first version of the measures added up all the revenue of each group and divided it by the number of days. But on the same day, some stores are on a SNAP day and the others are not, so each group has a different number of stores. The next example, will explain this in a simplified way. The example shos a day when only California has a SNAP day. (The numbers are made-up there is no need to focus on them).

*Each store sells $100 on a SNAP day and $90 on a regular day*

| Group | State(s) | Stores | Revenue | Divided by days | Result |
|-------|--------|--------|---------|-------------------|--------|
|SNAP | California | 4 | 4 * $100 = $400 | 1 | **$400** |
|Regular | Texas and Wisconsin | 6 | 6 * $90 = $540 | 1 | **$540** |

Dividing by days, the regular group looks better but only because it contains more stores, not because the stores sell more. It's like comparing a team of 4 people against a team of 6 by their total sales. 

**The fix:** divide each group's revenue by the number of stores that produced it on each day. 

| Group | Revenue | Divided by store-days | Result |
|---|---|---|---|
| SNAP | $400 | 4 | **$100 per store** | 
| Regular | $540 | 6 | **$90 per store** | 

Now both numbers mean the same, *how much one store sells in one day*, and SNAP comes out ahead. The key was dividing by what actually produced the revenue. 

**Result:** With real data the SNAP days sell **8.7% more** in 2016 and **11.7% more** in the period from 2011 to 2016.
The first negative result was a calculation error and not a real customer behavior.

*Note:The denominator `Distinct Days` (unique calendar days) was replaced by `Store/Days Combinations`, which count store-day pairs as its name suggests.*

## 2. Forecast: custom DAX measures instead of native Power BI forecast

**Decision:** The built-in forecast tool of Power BI was discarded because it does not show how it is calculated so the results cannot be explained or checked  and also this tool does not allow checking the forecast result against past real sales. 

Instead the forecast was built in DAX with a simple rule **each future day is the average of the same weekday in the 4 to 7 weeks before.** Because sales follow a weekly rhythm (weekends sell more than weekdays).

Example: the forecast for Saturday, June 18,2016 is the average of these 4 real Saturdays

| Weeks back | 4 | 5 | 6 | 7 |
|---|---|---|---|---|
|Date | May 21 | May 14 | May 7 | April 30 |

**Why these weeks:** The forecast covers the 28 days (4 full weeks) after the last real sale, so 4 weeks back is the closest point with real data for every forecast day. 

**Trade-off:** It only captures the weekly pattern but not the trend. For 28 days this is acceptable but in a growing series it can fall slightly short.

