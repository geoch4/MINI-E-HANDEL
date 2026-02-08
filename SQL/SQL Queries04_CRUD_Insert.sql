USE MiniehandelDB;
GO

/* ============================================================
   04_CRUD_Insert.sql
   INSERT - CRUD examples

   VG (B): Transaction example
   - Punkt 5 (Order + OrderItems + Payment) körs i en transaktion.
   - Vid fel: ROLLBACK + visar felmeddelande.
   - Rollback-scenario beskrivs i kommentarerna.
   ============================================================ */

---------------------------------------------------------------
-- 1) Insert a new customer (unique Email required)
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE Email = 'new.customer@gmail.com')
BEGIN
    INSERT INTO dbo.Customers (Email, Fullname, Phone)
    VALUES ('new.customer@gmail.com', 'New Customer', '0701231231');
END
GO

---------------------------------------------------------------
-- 2) Insert a new category (unique Name required)
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE Name = 'Gift Cards')
BEGIN
    INSERT INTO dbo.Categories (Name)
    VALUES ('Gift Cards');
END
GO

---------------------------------------------------------------
-- 3) Insert a new product (unique SKU required)
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE SKU = 'SKU-7777')
BEGIN
    INSERT INTO dbo.Products (Name, SKU, Price, IsActive)
    VALUES ('Gift Card 500 SEK', 'SKU-7777', 500.00, 1);
END
GO

---------------------------------------------------------------
-- 4) Connect product to category (many-to-many)
---------------------------------------------------------------
DECLARE @GiftCategoryId INT = (SELECT CategoryID FROM dbo.Categories WHERE Name='Gift Cards');
DECLARE @GiftProductId INT  = (SELECT ProductID  FROM dbo.Products   WHERE SKU='SKU-7777');

IF @GiftCategoryId IS NOT NULL AND @GiftProductId IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.ProductCategories
        WHERE ProductID=@GiftProductId AND CategoryID=@GiftCategoryId
    )
    BEGIN
        INSERT INTO dbo.ProductCategories (ProductID, CategoryID)
        VALUES (@GiftProductId, @GiftCategoryId);
    END
END
GO

---------------------------------------------------------------
-- 5) VG TRANSACTION: Create an order + 2 order items + payment
---------------------------------------------------------------
/*
Rollback scenario (VG):
- Om någon INSERT misslyckas (t.ex. FK-fel, fel datatyp, constraint),
  så ska hela ordern + orderrader + payment rullas tillbaka.
- Vi har även en "business check": om TotalAmount blir 0 eller NULL
  kastar vi ett fel med THROW -> vilket triggar ROLLBACK.
*/

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @CustomerId INT = (SELECT CustomerID FROM dbo.Customers WHERE Email='new.customer@gmail.com');
    DECLARE @OrderId INT;

    -- pick two active products
    DECLARE @Prod1 INT, @Prod2 INT;

    SELECT TOP 1 @Prod1 = ProductID
    FROM dbo.Products
    WHERE IsActive=1
    ORDER BY NEWID();

    SELECT TOP 1 @Prod2 = ProductID
    FROM dbo.Products
    WHERE IsActive=1 AND ProductID <> @Prod1
    ORDER BY NEWID();

    -- Guard clauses (stoppa transaktionen om vi saknar data)
    IF @CustomerId IS NULL
        THROW 50001, 'Customer not found for new.customer@gmail.com', 1;

    IF @Prod1 IS NULL OR @Prod2 IS NULL
        THROW 50002, 'Not enough active products to create an order.', 1;

    -- Create order
    INSERT INTO dbo.Orders (CustomerID, Status, TotalAmount)
    VALUES (@CustomerId, 'Pending', 0);

    SET @OrderId = SCOPE_IDENTITY();

    -- item 1 (quantity 1)
    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice, LineTotal)
    SELECT @OrderId, ProductID, 1, Price, Price
    FROM dbo.Products
    WHERE ProductID=@Prod1;

    -- item 2 (quantity 2)
    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice, LineTotal)
    SELECT @OrderId, ProductID, 2, Price, CAST(2*Price AS DECIMAL(10,2))
    FROM dbo.Products
    WHERE ProductID=@Prod2;

    -- update total
    UPDATE dbo.Orders
    SET TotalAmount = (SELECT SUM(LineTotal) FROM dbo.OrderItems WHERE OrderID=@OrderId)
    WHERE OrderID=@OrderId;

    -- Business check: total must be > 0
    IF (SELECT TotalAmount FROM dbo.Orders WHERE OrderID=@OrderId) IS NULL
       OR (SELECT TotalAmount FROM dbo.Orders WHERE OrderID=@OrderId) <= 0
    BEGIN
        THROW 50003, 'TotalAmount must be greater than 0 after inserting items.', 1;
    END

    -- add payment + set order paid
    INSERT INTO dbo.Payments (OrderID, PaymentOption, Amount, PaymentStatus, PaidAt)
    VALUES (
        @OrderId,
        'Card',
        (SELECT TotalAmount FROM dbo.Orders WHERE OrderID=@OrderId),
        'Paid',
        SYSUTCDATETIME()
    );

    UPDATE dbo.Orders
    SET Status='Paid'
    WHERE OrderID=@OrderId;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;

    -- Visa fel så du kan bevisa rollback-beteende i rättning
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO
