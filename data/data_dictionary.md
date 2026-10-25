# Data dictionary

## 1. Source file: `SalesData.csv`

32,718 rows, nine columns, 1 July 2019 to 31 December 2021. Grain: one row per sales order line. No missing values; no duplicate (order number, line number) pairs.

| Column | Type in source | Description |
| --- | --- | --- |
| `SalesOrderNumber` | text | Sales order identifier, for example `SO43701`. 16,459 distinct orders |
| `SalesOrderLineNumber` | integer | Line within the order. Together with the order number it is unique |
| `OrderDate` | date (`YYYY-MM-DD`) | Date of the order |
| `CustomerName` | text | Customer full name. Not unique: 39 names map to more than one email |
| `EmailAddress` | text | Customer email. 12,427 distinct values; used as the customer key |
| `Item` | text | Product name including colour and size, for example `Road-150 Red, 48`. 130 distinct items |
| `Quantity` | integer | Units on the line. Always 1 in this dataset |
| `UnitPrice` | decimal | Price per unit before tax |
| `TaxAmount` | decimal | Tax on the line |

## 2. Lakehouse tables

| Table | Built by | Adds to the source columns |
| --- | --- | --- |
| `sales_data_stage` | PySpark notebook | Types applied (`OrderDate` as date, `UnitPrice` and `TaxAmount` as decimal(18,4)), plus `Year` and `Month`. 32,718 rows (2019: 1,201; 2020: 2,733; 2021: 28,784) |
| `sales_data_curated` | Dataflow Gen2 | `FirstName` (text before the first space) and `LastName` (everything after the first space). `CustomerName` is kept |

## 3. Warehouse tables (schema `Sales`)

### `Sales.Fact_Sales`: one row per order line

| Column | Type | Description |
| --- | --- | --- |
| `CustomerID` | VARCHAR(255) | Customer email; joins to `Dim_Customer[CustomerID]` |
| `ItemID` | VARCHAR(255) | Item name; joins to `Dim_Item[ItemID]` |
| `SalesOrderNumber` | VARCHAR(30) | Order identifier |
| `SalesOrderLineNumber` | INT | Line number within the order |
| `OrderDate` | DATE | Order date; joins to `Dim_Date[DateKey]` |
| `Quantity` | INT | Units on the line |
| `TaxAmount` | FLOAT | Tax on the line |
| `UnitPrice` | FLOAT | Unit price |
| `Year` | INT | Calendar year (kept from staging; report uses `Dim_Date[Year]` instead) |
| `Month` | INT | Calendar month number (same note) |

### `Sales.Dim_Customer`: one row per customer

| Column | Type | Description |
| --- | --- | --- |
| `CustomerID` | VARCHAR(255) | Email address (primary key, not enforced) |
| `CustomerName` | VARCHAR(255) | Full name |
| `FirstName` | VARCHAR(255) | First name |
| `LastName` | VARCHAR(255) | Last name (may be multi-word) |
| `EmailAddress` | VARCHAR(255) | Email; hidden from report users |

### `Sales.Dim_Item`: one row per product

| Column | Type | Description |
| --- | --- | --- |
| `ItemID` | VARCHAR(255) | Item name (primary key, not enforced) |
| `ItemName` | VARCHAR(255) | Item name shown in the report |
| `Category` | VARCHAR(30) | Bikes, Accessories or Clothing (derived from item name) |
| `Subcategory` | VARCHAR(30) | 17 values, for example Road Bikes, Helmets, Jerseys (derived from item name) |

### `Sales.Dim_Date`: one row per calendar day, 1 January 2019 to 31 December 2021 (1,096 rows)

| Column | Type | Description | Sort-by |
| --- | --- | --- | --- |
| `DateKey` | DATE | Calendar date; marked as the date table key | |
| `Year` | INT | Calendar year | |
| `QuarterNumber` | INT | 1 to 4 | |
| `QuarterName` | VARCHAR(2) | Q1 to Q4 | `QuarterNumber` |
| `MonthNumber` | INT | 1 to 12 | |
| `MonthName` | VARCHAR(20) | January to December | `MonthNumber` |
| `MonthShort` | VARCHAR(3) | Jan to Dec | `MonthNumber` |
| `YearMonth` | VARCHAR(8) | For example `2021-03` | `YearMonthSort` |
| `YearMonthSort` | INT | For example `202103` | |
| `DayOfMonth` | INT | 1 to 31 | |
| `DayName` | VARCHAR(20) | Monday to Sunday | `DayOfWeekNumber` |
| `DayOfWeekNumber` | INT | 1 (Monday) to 7 (Sunday) | |
| `IsWeekend` | VARCHAR(3) | Yes or No | |

Sales data starts on 1 July 2019, so 1 January to 30 June 2019 exist in `Dim_Date` but have no sales.

## 4. Semantic model `Sales_Reporting_Model`

Relationships (all one-to-many, single direction, active):

| One side | Many side |
| --- | --- |
| `Dim_Customer[CustomerID]` | `Fact_Sales[CustomerID]` |
| `Dim_Item[ItemID]` | `Fact_Sales[ItemID]` |
| `Dim_Date[DateKey]` | `Fact_Sales[OrderDate]` |

Model settings: `Dim_Date` marked as the date table; sort-by columns as in the table above; numeric columns such as `Year`, `Month`, `Quantity`, `UnitPrice` and `TaxAmount` set to "Don't summarize"; technical IDs and `EmailAddress` hidden from report view.

## 5. Measures (`dax/Sales_Measures.dax`)

| Measure | Definition | Notes |
| --- | --- | --- |
| `Units Sold` | `SUM ( Fact_Sales[Quantity] )` | 32,718 overall |
| `Order Count` | `DISTINCTCOUNT ( Fact_Sales[SalesOrderNumber] )` | 16,459 overall |
| `Gross Sales` | `SUMX ( Fact_Sales, Quantity * UnitPrice )` | $20,928,022 overall |
| `Tax Amount` | `SUM ( Fact_Sales[TaxAmount] )` | $1,674,242 overall |
| `Avg Order Value` | `DIVIDE ( [Gross Sales], [Order Count] )` | $1,272 overall |
| `Date Range` | `FORMAT` of the first and last order dates | Subtitle card: "Jul 2019 to Dec 2021" |
| `Trend Title` | `SWITCH` on the selected year and quarter | Dynamic title for the drillable trend chart |
| `Heat Index` | `[Gross Sales]` divided by the row's peak month | Drives the heatmap colours; range 0 to 1 |
| `Sales 2020`, `Sales 2021`, `Growth 2020 to 2021` | Fixed-year sales and growth | 2019 is excluded because it is a partial year |

The file also contains optional time-intelligence measures (`Sales PY`, `YoY %`, `Sales YTD`, `MoM %`, `Sales Rolling 3M`) and ranking and share measures.
