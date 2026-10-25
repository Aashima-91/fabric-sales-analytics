-- Dim_Date for Leadership_Reporting_DWH (run in the WAREHOUSE query editor, not the Lakehouse endpoint)
-- Builds a CONTIGUOUS calendar (every day from 1 Jan of the first sales year to 31 Dec of the last).
-- Time-intelligence DAX (SAMEPERIODLASTYEAR, DATESYTD) needs no missing dates, which is why this
-- replaces the SELECT DISTINCT OrderDate version in Step 39 of the guide.
-- No recursive CTE: Fabric Warehouse does not support them, so a digits cross-join generates the numbers.

DROP TABLE IF EXISTS Sales.Dim_Date;
GO

CREATE TABLE Sales.Dim_Date
(
    DateKey          DATE         NOT NULL,
    [Year]           INT          NOT NULL,
    QuarterNumber    INT          NOT NULL,
    QuarterName      VARCHAR(2)   NOT NULL,   -- Q1..Q4
    MonthNumber      INT          NOT NULL,   -- 1..12 (use as Sort By column)
    MonthName        VARCHAR(20)  NOT NULL,   -- January..December
    MonthShort       VARCHAR(3)   NOT NULL,   -- Jan..Dec
    YearMonth        VARCHAR(8)   NOT NULL,   -- 2021-03
    YearMonthSort    INT          NOT NULL,   -- 202103 (Sort By column for YearMonth)
    DayOfMonth       INT          NOT NULL,
    DayName          VARCHAR(20)  NOT NULL,
    DayOfWeekNumber  INT          NOT NULL,   -- 1 = Monday .. 7 = Sunday
    IsWeekend        VARCHAR(3)   NOT NULL    -- Yes / No
);
GO

DECLARE @StartDate DATE = (SELECT DATEFROMPARTS(YEAR(MIN(OrderDate)), 1, 1)  FROM Sales.Fact_Sales);
DECLARE @EndDate   DATE = (SELECT DATEFROMPARTS(YEAR(MAX(OrderDate)), 12, 31) FROM Sales.Fact_Sales);

WITH Digits AS (
    SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS d(n)
),
Numbers AS (
    SELECT a.n + 10*b.n + 100*c.n + 1000*d.n AS n      -- 0 .. 9999 (about 27 years)
    FROM Digits a CROSS JOIN Digits b CROSS JOIN Digits c CROSS JOIN Digits d
),
Cal AS (
    SELECT DATEADD(DAY, n, @StartDate) AS d
    FROM Numbers
    WHERE DATEADD(DAY, n, @StartDate) <= @EndDate
)
INSERT INTO Sales.Dim_Date
(DateKey, [Year], QuarterNumber, QuarterName, MonthNumber, MonthName, MonthShort,
 YearMonth, YearMonthSort, DayOfMonth, DayName, DayOfWeekNumber, IsWeekend)
SELECT
    d,
    YEAR(d),
    DATEPART(QUARTER, d),
    CONCAT('Q', DATEPART(QUARTER, d)),
    MONTH(d),
    DATENAME(MONTH, d),
    LEFT(DATENAME(MONTH, d), 3),
    CONCAT(YEAR(d), '-', RIGHT(CONCAT('0', MONTH(d)), 2)),
    YEAR(d) * 100 + MONTH(d),
    DAY(d),
    DATENAME(WEEKDAY, d),
    ((DATEPART(WEEKDAY, d) + @@DATEFIRST - 2) % 7) + 1,   -- Monday = 1 regardless of DATEFIRST
    CASE WHEN ((DATEPART(WEEKDAY, d) + @@DATEFIRST - 2) % 7) + 1 >= 6 THEN 'Yes' ELSE 'No' END
FROM Cal;
GO

-- Checks: expect 1,096 rows for 2019-2021 (365 + 366 + 365), no gaps, and no orphan sales dates
SELECT COUNT(*) AS DateRows, MIN(DateKey) AS FirstDate, MAX(DateKey) AS LastDate FROM Sales.Dim_Date;

SELECT COUNT(*) AS OrphanFactDates
FROM Sales.Fact_Sales f
LEFT JOIN Sales.Dim_Date d ON f.OrderDate = d.DateKey
WHERE d.DateKey IS NULL;   -- expect 0

-- After running: Sales_Reporting_Model -> Home -> Edit tables -> tick Dim_Date -> Confirm.
-- Then relate Dim_Date[DateKey] (1) -> Fact_Sales[OrderDate] (*), single direction, active,
-- and Mark as date table on Dim_Date[DateKey].
