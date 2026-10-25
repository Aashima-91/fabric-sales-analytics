-- Run in the Warehouse (Leadership_Reporting_DWH), not the Lakehouse SQL endpoint.
-- Based on the supplied SchemaFact&DimTablesQueryFabricDWH.sql from the Fabric sample project.
-- Run CREATE SCHEMA once in an empty warehouse. Primary keys are NOT ENFORCED in Fabric Warehouse:
-- they document intended uniqueness but do not prevent duplicates (see 05_validation_checks.sql).

CREATE SCHEMA [Sales];
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Fact_Sales' AND SCHEMA_NAME(schema_id) = 'Sales')
    CREATE TABLE Sales.Fact_Sales (
        CustomerID           VARCHAR(255) NOT NULL,   -- customer email
        ItemID               VARCHAR(255) NOT NULL,   -- item name
        SalesOrderNumber     VARCHAR(30),
        SalesOrderLineNumber INT,
        OrderDate            DATE,
        Quantity             INT,
        TaxAmount            FLOAT,
        UnitPrice            FLOAT,
        [Year]               INT,
        [Month]              INT
    );

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dim_Customer' AND SCHEMA_NAME(schema_id) = 'Sales')
    CREATE TABLE Sales.Dim_Customer (
        CustomerID   VARCHAR(255) NOT NULL,
        CustomerName VARCHAR(255) NOT NULL,
        FirstName    VARCHAR(255) NOT NULL,
        LastName     VARCHAR(255) NOT NULL,
        EmailAddress VARCHAR(255) NOT NULL
    );
GO

ALTER TABLE Sales.Dim_Customer
    ADD CONSTRAINT PK_Dim_Customer PRIMARY KEY NONCLUSTERED (CustomerID) NOT ENFORCED;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dim_Item' AND SCHEMA_NAME(schema_id) = 'Sales')
    CREATE TABLE Sales.Dim_Item (
        ItemID   VARCHAR(255) NOT NULL,
        ItemName VARCHAR(255) NOT NULL
    );
GO

ALTER TABLE Sales.Dim_Item
    ADD CONSTRAINT PK_Dim_Item PRIMARY KEY NONCLUSTERED (ItemID) NOT ENFORCED;
GO
