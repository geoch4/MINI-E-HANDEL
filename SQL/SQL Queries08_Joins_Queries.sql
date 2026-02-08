USE MiniehandelDB;
GO

/* JOIN queries - show relationships */

-- 1) Orders with customer name + payment status
SELECT
    o.OrderID,
    o.OrderDate,
    o.Status AS OrderStatus,
    o.TotalAmount,
    c.Fullname AS CustomerName,
    c.Email,
    p.PaymentOption,
    p.PaymentStatus
FROM dbo.Orders o
JOIN dbo.Customers c ON c.CustomerID = o.CustomerID
LEFT JOIN dbo.Payments p ON p.OrderID = o.OrderID
ORDER BY o.OrderDate DESC;

-- 2) Order details: order + items + product
SELECT
    o.OrderID,
    c.Fullname AS CustomerName,
    oi.Quantity,
    pr.Name AS ProductName,
    oi.UnitPrice,
    oi.LineTotal
FROM dbo.Orders o
JOIN dbo.Customers c ON c.CustomerID = o.CustomerID
JOIN dbo.OrderItems oi ON oi.OrderID = o.OrderID
JOIN dbo.Products pr ON pr.ProductID = oi.ProductID
ORDER BY o.OrderID;

-- 3) Products with categories (many-to-many)
SELECT
    pr.ProductID,
    pr.Name AS ProductName,
    pr.SKU,
    pr.Price,
    ca.Name AS CategoryName
FROM dbo.Products pr
LEFT JOIN dbo.ProductCategories pc ON pc.ProductID = pr.ProductID
LEFT JOIN dbo.Categories ca ON ca.CategoryID = pc.CategoryID
ORDER BY pr.Name, ca.Name;

-- 4) Products with stock (Inventory)
SELECT
    pr.ProductID,
    pr.Name,
    pr.SKU,
    i.StockQuantity,
    i.UpdatedAt
FROM dbo.Products pr
JOIN dbo.Inventory i ON i.ProductID = pr.ProductID
ORDER BY i.StockQuantity ASC;

-- 5) Total sales per customer (only Paid payments)
SELECT
    c.Fullname,
    SUM(o.TotalAmount) AS TotalSales
FROM dbo.Customers c
JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
JOIN dbo.Payments p ON p.OrderID = o.OrderID
WHERE p.PaymentStatus = 'Paid'
GROUP BY c.Fullname
ORDER BY TotalSales DESC;
GO
