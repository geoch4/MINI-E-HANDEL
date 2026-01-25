USE MiniehandelDB;
GO

/* DELETE - CRUD examples */

-- IMPORTANT:
-- Because of FK constraints, you must delete dependent rows first.

-- 1) Delete a random order (and its items + payments)
DECLARE @OrderId INT = (SELECT TOP 1 OrderID FROM dbo.Orders ORDER BY NEWID());

IF @OrderId IS NOT NULL
BEGIN
    DELETE FROM dbo.Payments   WHERE OrderID = @OrderId;
    DELETE FROM dbo.OrderItems WHERE OrderID = @OrderId;
    DELETE FROM dbo.Orders     WHERE OrderID = @OrderId;
END
GO

-- 2) Delete a category ONLY if no ProductCategories rows exist
-- (Example: 'Gift Cards' if it exists)
IF EXISTS (SELECT 1 FROM dbo.Categories WHERE Name='Gift Cards')
BEGIN
    DECLARE @CatId INT = (SELECT CategoryID FROM dbo.Categories WHERE Name='Gift Cards');

    DELETE FROM dbo.ProductCategories WHERE CategoryID = @CatId;
    DELETE FROM dbo.Categories WHERE CategoryID = @CatId;
END
GO

-- 3) Products: recommended "soft delete" (IsActive=0) instead of DELETE
-- (Because Inventory + ProductCategories + OrderItems depend on products)
-- UPDATE dbo.Products SET IsActive=0 WHERE SKU='SKU-7777';
GO
