-- Adds Category and Subcategory to Sales.Dim_Item (run in the Warehouse, not the Lakehouse endpoint).
-- Why physical columns: Direct Lake semantic models do not allow calculated columns.
-- Categories are derived from item-name patterns because the source has no product hierarchy.
-- Run once after Dim_Item is loaded; rerun the two UPDATE statements after any reload of Dim_Item.

ALTER TABLE Sales.Dim_Item ADD Category VARCHAR(30) NULL;
ALTER TABLE Sales.Dim_Item ADD Subcategory VARCHAR(30) NULL;
GO

UPDATE Sales.Dim_Item
SET Subcategory =
    CASE
        WHEN ItemName LIKE 'Mountain-%' THEN 'Mountain Bikes'
        WHEN ItemName LIKE 'Road-%'     THEN 'Road Bikes'
        WHEN ItemName LIKE 'Touring-%'  THEN 'Touring Bikes'
        WHEN ItemName LIKE '%Helmet%'   THEN 'Helmets'
        WHEN ItemName LIKE '%Tire%' OR ItemName LIKE 'Patch Kit%' THEN 'Tires and Tubes'
        WHEN ItemName LIKE '%Bottle Cage%' OR ItemName LIKE 'Water Bottle%' THEN 'Bottles and Cages'
        WHEN ItemName LIKE 'Hydration Pack%' THEN 'Hydration Packs'
        WHEN ItemName LIKE '%Rack%'     THEN 'Bike Racks'
        WHEN ItemName LIKE '%Stand%'    THEN 'Bike Stands'
        WHEN ItemName LIKE 'Bike Wash%' THEN 'Cleaners'
        WHEN ItemName LIKE 'Fender%'    THEN 'Fenders'
        WHEN ItemName LIKE '%Cap'       THEN 'Caps'
        WHEN ItemName LIKE '%Gloves%'   THEN 'Gloves'
        WHEN ItemName LIKE '%Jersey%'   THEN 'Jerseys'
        WHEN ItemName LIKE '%Shorts%'   THEN 'Shorts'
        WHEN ItemName LIKE '%Socks%'    THEN 'Socks'
        WHEN ItemName LIKE '%Vest%'     THEN 'Vests'
        ELSE 'Other'
    END;

UPDATE Sales.Dim_Item
SET Category =
    CASE
        WHEN Subcategory IN ('Mountain Bikes','Road Bikes','Touring Bikes') THEN 'Bikes'
        WHEN Subcategory IN ('Caps','Gloves','Jerseys','Shorts','Socks','Vests') THEN 'Clothing'
        WHEN Subcategory = 'Other' THEN 'Other'
        ELSE 'Accessories'
    END;

-- Check: expect 130 items in total and no 'Other'
SELECT Category, Subcategory, COUNT(*) AS Items
FROM Sales.Dim_Item
GROUP BY Category, Subcategory
ORDER BY Category, Subcategory;
