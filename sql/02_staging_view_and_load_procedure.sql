-- Run in the Warehouse after 01_create_schema_and_tables.sql.
-- The Lakehouse (Data_Staging_Lakehouse) must be added to the Warehouse explorer first.

-- 1. Staging view over the curated Lakehouse table
CREATE VIEW [Sales].[staging_salesdata]
AS
SELECT SalesOrderNumber, SalesOrderLineNumber, OrderDate,
       CustomerName, FirstName, LastName, EmailAddress,
       Item, Quantity, UnitPrice, TaxAmount, [Year], [Month]
FROM [Data_Staging_Lakehouse].[dbo].[sales_data_curated];
GO

-- 2. Idempotent load procedure, run once per year.
-- Differences from the original sample procedure:
--   * CustomerID is the email address (39 customer names map to more than one email).
--   * Fact rows are skipped if the same order number and line number already exist,
--     so rerunning a year does not duplicate sales lines.
DROP PROCEDURE IF EXISTS [Sales].[LoadDataFromStagingLakehouse];
GO
CREATE PROCEDURE [Sales].[LoadDataFromStagingLakehouse]
    @OrderYear INT
AS
BEGIN
    INSERT INTO Sales.Dim_Customer
        (CustomerID, CustomerName, FirstName, LastName, EmailAddress)
    SELECT DISTINCT s.EmailAddress, s.CustomerName,
           s.FirstName, s.LastName, s.EmailAddress
    FROM Sales.staging_salesdata AS s
    WHERE YEAR(s.OrderDate) = @OrderYear
      AND NOT EXISTS (
          SELECT 1 FROM Sales.Dim_Customer AS d
          WHERE d.CustomerID = s.EmailAddress);

    INSERT INTO Sales.Dim_Item (ItemID, ItemName)
    SELECT DISTINCT s.Item, s.Item
    FROM Sales.staging_salesdata AS s
    WHERE YEAR(s.OrderDate) = @OrderYear
      AND NOT EXISTS (
          SELECT 1 FROM Sales.Dim_Item AS d
          WHERE d.ItemID = s.Item);

    INSERT INTO Sales.Fact_Sales
        (CustomerID, ItemID, SalesOrderNumber,
         SalesOrderLineNumber, OrderDate, Quantity,
         TaxAmount, UnitPrice, [Year], [Month])
    SELECT s.EmailAddress, s.Item,
           s.SalesOrderNumber,
           CAST(s.SalesOrderLineNumber AS INT),
           CAST(s.OrderDate AS DATE),
           CAST(s.Quantity AS INT),
           CAST(s.TaxAmount AS FLOAT),
           CAST(s.UnitPrice AS FLOAT),
           s.[Year], s.[Month]
    FROM Sales.staging_salesdata AS s
    WHERE YEAR(s.OrderDate) = @OrderYear
      AND NOT EXISTS (
          SELECT 1 FROM Sales.Fact_Sales AS f
          WHERE f.SalesOrderNumber = s.SalesOrderNumber
            AND f.SalesOrderLineNumber =
                CAST(s.SalesOrderLineNumber AS INT));
END;
GO

-- 3. Load all history
EXEC [Sales].[LoadDataFromStagingLakehouse] @OrderYear = 2019;
EXEC [Sales].[LoadDataFromStagingLakehouse] @OrderYear = 2020;
EXEC [Sales].[LoadDataFromStagingLakehouse] @OrderYear = 2021;
