USE MiniehandelDB;
GO

/* INSERT - CRUD examples */

-- 1) Insert a new customer (unique Email required)
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE Email = 'new.customer@gmail.com')
BEGIN
    INSERT INTO dbo.Customers (Email, Fullname, Phone)
    VALUES ('new.customer@gmail.com', 'New Customer', '0701231231');
END
GO

-- 2) Insert a new category (unique Name required)
IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Name = 'Gift Cards')
BEGIN
    INSERT INTO dbo.Categories (Name)
    VALUES ('Gift Cards');
END
GO

-- 3) Insert a new product (unique SKU required)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE SKU = 'SKU-7777')
BEGIN
    INSERT INTO dbo.Products (Name, SKU, Price, IsActive)
    VALUES ('Gift Card 500 SEK', 'SKU-7777', 500.00, 1);
END
GO

-- 4) Connect product to category (many-to-many)
DECLARE @GiftCategoryId INT = (SELECT CategoryID FROM dbo.Categories WHERE Name='Gift Cards');
DECLARE @GiftProductId INT  = (SELECT ProductID FROM dbo.Products WHERE SKU='SKU-7777');

IF @GiftCategoryId IS NOT NULL AND @GiftProductId IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM dbo.ProductCategories
        WHERE ProductID=@GiftProductId AND CategoryID=@GiftCategoryId
    )
    BEGIN
        INSERT INTO dbo.ProductCategories (ProductID, CategoryID)
        VALUES (@GiftProductId, @GiftCategoryId);
    END
END
GO

-- 5) Create an order + 2 order items + payment
DECLARE @CustomerId INT = (SELECT CustomerID FROM dbo.Customers WHERE Email='new.customer@gmail.com');

DECLARE @OrderId INT;

-- pick two active products
DECLARE @Prod1 INT, @Prod2 INT;

SELECT TOP 1 @Prod1 = ProductID FROM dbo.Products WHERE IsActive=1 ORDER BY NEWID();
SELECT TOP 1 @Prod2 = ProductID FROM dbo.Products WHERE IsActive=1 AND ProductID <> @Prod1 ORDER BY NEWID();

IF @CustomerId IS NOT NULL AND @Prod1 IS NOT NULL AND @Prod2 IS NOT NULL
BEGIN
    INSERT INTO dbo.Orders (CustomerID, Status, TotalAmount)
    VALUES (@CustomerId, 'Pending', 0);

    SET @OrderId = SCOPE_IDENTITY();

    -- item 1
    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice, LineTotal)
    SELECT @OrderId, ProductID, 1, Price, Price
    FROM dbo.Products WHERE ProductID=@Prod1;

    -- item 2 (quantity 2)
    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice, LineTotal)
    SELECT @OrderId, ProductID, 2, Price, CAST(2*Price AS DECIMAL(10,2))
    FROM dbo.Products WHERE ProductID=@Prod2;

    -- update total
    UPDATE dbo.Orders
    SET TotalAmount = (SELECT SUM(LineTotal) FROM dbo.OrderItems WHERE OrderID=@OrderId)
    WHERE OrderID=@OrderId;

    -- add payment + set order paid
    INSERT INTO dbo.Payments (OrderID, PaymentOption, Amount, PaymentStatus, PaidAt)
    VALUES (@OrderId, 'Card', (SELECT TotalAmount FROM dbo.Orders WHERE OrderID=@OrderId), 'Paid', SYSUTCDATETIME());

    UPDATE dbo.Orders SET Status='Paid' WHERE OrderID=@OrderId;
END
GO
