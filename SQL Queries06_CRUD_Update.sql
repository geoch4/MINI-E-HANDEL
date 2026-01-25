USE MiniehandelDB;
GO

/* UPDATE - CRUD examples */

-- 1) Update customer phone
UPDATE dbo.Customers
SET Phone = '0709990000'
WHERE Email = 'anna.andersson@gmail.com';

-- 2) Increase price for a product by SKU
UPDATE dbo.Products
SET Price = Price + 100
WHERE SKU = 'SKU-1001';

-- 3) Deactivate a product (soft delete pattern)
UPDATE dbo.Products
SET IsActive = 0
WHERE SKU = 'SKU-9001';

-- 4) Update inventory (add stock for a SKU)
UPDATE i
SET i.StockQuantity = i.StockQuantity + 20,
    i.UpdatedAt = SYSUTCDATETIME()
FROM dbo.Inventory i
JOIN dbo.Products p ON p.ProductID = i.ProductID
WHERE p.SKU = 'SKU-1002';

-- 5) Change order status (must match CHECK constraint)
DECLARE @SomeOrderId INT = (SELECT TOP 1 OrderID FROM dbo.Orders ORDER BY NEWID());
UPDATE dbo.Orders
SET Status = 'Shipped'
WHERE OrderID = @SomeOrderId;
GO
