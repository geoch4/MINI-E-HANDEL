USE MiniehandelDB;
GO

/* STORED PROCEDURES */

-- 1) Create Order + one item
CREATE OR ALTER PROCEDURE dbo.sp_CreateOrderWithSingleItem
    @CustomerEmail VARCHAR(250),
    @ProductSKU VARCHAR(50),
    @Quantity INT,
    @PaymentOption VARCHAR(30) = 'Card'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerID INT = (SELECT CustomerID FROM dbo.Customers WHERE Email=@CustomerEmail);
    DECLARE @ProductID INT;
    DECLARE @UnitPrice DECIMAL(10,2);

    SELECT @ProductID = ProductID, @UnitPrice = Price
    FROM dbo.Products
    WHERE SKU=@ProductSKU;

    IF @CustomerID IS NULL
    BEGIN
        RAISERROR('Customer email not found.', 16, 1);
        RETURN;
    END

    IF @ProductID IS NULL
    BEGIN
        RAISERROR('Product SKU not found.', 16, 1);
        RETURN;
    END

    IF @Quantity <= 0
    BEGIN
        RAISERROR('Quantity must be greater than 0.', 16, 1);
        RETURN;
    END

    DECLARE @OrderID INT;

    INSERT INTO dbo.Orders (CustomerID, Status, TotalAmount)
    VALUES (@CustomerID, 'Pending', 0);

    SET @OrderID = SCOPE_IDENTITY();

    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice, LineTotal)
    VALUES (@OrderID, @ProductID, @Quantity, @UnitPrice, CAST(@Quantity*@UnitPrice AS DECIMAL(10,2)));

    UPDATE dbo.Orders
    SET TotalAmount = (SELECT SUM(LineTotal) FROM dbo.OrderItems WHERE OrderID=@OrderID)
    WHERE OrderID=@OrderID;

    INSERT INTO dbo.Payments (OrderID, PaymentOption, Amount, PaymentStatus, PaidAt)
    VALUES (@OrderID, @PaymentOption, (SELECT TotalAmount FROM dbo.Orders WHERE OrderID=@OrderID), 'Paid', SYSUTCDATETIME());

    UPDATE dbo.Orders SET Status='Paid' WHERE OrderID=@OrderID;

    SELECT @OrderID AS NewOrderID;
END
GO

-- 2) Update order status (safe with CHECK list)
CREATE OR ALTER PROCEDURE dbo.sp_UpdateOrderStatus
    @OrderID INT,
    @NewStatus VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @NewStatus NOT IN ('Pending','Paid','Cancelled','Shipped','Completed')
    BEGIN
        RAISERROR('Invalid status value.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Orders
    SET Status = @NewStatus
    WHERE OrderID = @OrderID;

    SELECT OrderID, Status FROM dbo.Orders WHERE OrderID=@OrderID;
END
GO

-- Example calls:
-- EXEC dbo.sp_CreateOrderWithSingleItem 'anna.andersson@gmail.com', 'SKU-1001', 2, 'Swish';
-- EXEC dbo.sp_UpdateOrderStatus 1, 'Shipped';
GO
