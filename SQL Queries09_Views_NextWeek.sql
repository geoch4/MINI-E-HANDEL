USE MiniehandelDB;
GO

/* VIEWS */

-- View 1: Product overview (product + stock)
CREATE OR ALTER VIEW dbo.vw_ProductStock
AS
SELECT
    pr.ProductID,
    pr.Name,
    pr.SKU,
    pr.Price,
    pr.IsActive,
    i.StockQuantity,
    i.UpdatedAt
FROM dbo.Products pr
JOIN dbo.Inventory i ON i.ProductID = pr.ProductID;
GO

-- View 2: Order summary (order + customer + payment)
CREATE OR ALTER VIEW dbo.vw_OrderSummary
AS
SELECT
    o.OrderID,
    o.OrderDate,
    o.Status AS OrderStatus,
    o.TotalAmount,
    c.Fullname AS CustomerName,
    c.Email,
    p.PaymentStatus,
    p.PaymentOption,
    p.PaidAt
FROM dbo.Orders o
JOIN dbo.Customers c ON c.CustomerID = o.CustomerID
LEFT JOIN dbo.Payments p ON p.OrderID = o.OrderID;
GO

-- Test
SELECT TOP (20) * FROM dbo.vw_ProductStock ORDER BY StockQuantity ASC;
SELECT TOP (20) * FROM dbo.vw_OrderSummary ORDER BY OrderDate DESC;
GO
