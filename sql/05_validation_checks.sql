-- Validation queries for the Warehouse load. Run in Leadership_Reporting_DWH.
-- Expected results are in the comments.

-- 1. Row counts by year: 2019 = 1,201; 2020 = 2,733; 2021 = 28,784; total 32,718
SELECT [Year], COUNT(*) AS SalesLines FROM Sales.Fact_Sales GROUP BY [Year] ORDER BY [Year];
SELECT COUNT(*) AS FactRows FROM Sales.Fact_Sales;

-- 2. No duplicate order lines at the intended grain: expect zero rows
SELECT SalesOrderNumber, SalesOrderLineNumber, COUNT(*) AS Copies
FROM Sales.Fact_Sales
GROUP BY SalesOrderNumber, SalesOrderLineNumber
HAVING COUNT(*) > 1;

-- 3. Dimension keys are unique: expect zero rows from each
SELECT CustomerID, COUNT(*) AS Copies FROM Sales.Dim_Customer GROUP BY CustomerID HAVING COUNT(*) > 1;
SELECT ItemID, COUNT(*) AS Copies FROM Sales.Dim_Item GROUP BY ItemID HAVING COUNT(*) > 1;

-- 4. Every fact row resolves to a dimension row: expect 0 for each
SELECT COUNT(*) AS MissingCustomerKeys
FROM Sales.Fact_Sales AS f
LEFT JOIN Sales.Dim_Customer AS c ON f.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

SELECT COUNT(*) AS MissingItemKeys
FROM Sales.Fact_Sales AS f
LEFT JOIN Sales.Dim_Item AS i ON f.ItemID = i.ItemID
WHERE i.ItemID IS NULL;

SELECT COUNT(*) AS MissingDates
FROM Sales.Fact_Sales AS f
LEFT JOIN Sales.Dim_Date AS d ON f.OrderDate = d.DateKey
WHERE d.DateKey IS NULL;

-- 5. Idempotency test: run these three statements together; the count must not change
SELECT COUNT(*) AS BeforeRerun FROM Sales.Fact_Sales;
EXEC [Sales].[LoadDataFromStagingLakehouse] @OrderYear = 2021;
SELECT COUNT(*) AS AfterRerun FROM Sales.Fact_Sales;

-- 6. Items without a category: expect 0
SELECT COUNT(*) AS UncategorisedItems FROM Sales.Dim_Item WHERE Category IS NULL OR Category = 'Other';
