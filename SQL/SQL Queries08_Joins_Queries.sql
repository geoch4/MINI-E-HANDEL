USE MiniehandelDB;
GO

/* ============================================================
   08_Joins_Queries.sql  (VG)
   Krav:
   - 5 JOIN queries (minst 1 joinar 3 tabeller)
   - 2 aggregation queries (GROUP BY + HAVING)
   - 1 query med subquery eller CTE
   - 1 query som svarar på en affärsfråga
   ============================================================ */

---------------------------------------------------------------
-- JOIN QUERIES (5 st) - show relationships
---------------------------------------------------------------

-- JOIN 1) Orders with customer name + payment status
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
GO

-- JOIN 2) Order details: order + items + product (3+ tables)
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
GO

-- JOIN 3) Products with categories (many-to-many)
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
GO

-- JOIN 4) Products with stock (Inventory)
SELECT
    pr.ProductID,
    pr.Name,
    pr.SKU,
    i.StockQuantity,
    i.UpdatedAt
FROM dbo.Products pr
JOIN dbo.Inventory i ON i.ProductID = pr.ProductID
ORDER BY i.StockQuantity ASC;
GO

-- JOIN 5) Orders that have no payment record yet (useful follow-up list)
-- (No need to know Payments PK for this query)
SELECT
    o.OrderID,
    o.OrderDate,
    o.Status AS OrderStatus,
    o.TotalAmount,
    c.Fullname AS CustomerName,
    c.Email
FROM dbo.Orders o
JOIN dbo.Customers c ON c.CustomerID = o.CustomerID
LEFT JOIN dbo.Payments p ON p.OrderID = o.OrderID
WHERE p.OrderID IS NULL
ORDER BY o.OrderDate DESC;
GO


---------------------------------------------------------------
-- AGGREGATION (2 st) - GROUP BY / HAVING
---------------------------------------------------------------

-- AGG 1) Total sales per customer (only Paid payments)  (din query)
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

-- AGG 2) Customers with at least 2 orders (GROUP BY + HAVING)
SELECT
    c.CustomerID,
    c.Fullname,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalOrderedAmount
FROM dbo.Customers c
JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Fullname
HAVING COUNT(o.OrderID) >= 2
ORDER BY OrderCount DESC, TotalOrderedAmount DESC;
GO


---------------------------------------------------------------
-- CTE / SUBQUERY (1 st)
---------------------------------------------------------------

-- CTE) Top 5 best-selling products by quantity (and revenue)
WITH ProductSales AS
(
    SELECT
        pr.ProductID,
        pr.Name AS ProductName,
        SUM(oi.Quantity) AS TotalQuantity,
        SUM(oi.LineTotal) AS TotalRevenue
    FROM dbo.OrderItems oi
    JOIN dbo.Products pr ON pr.ProductID = oi.ProductID
    GROUP BY pr.ProductID, pr.Name
)
SELECT TOP (5)
    ProductID,
    ProductName,
    TotalQuantity,
    TotalRevenue
FROM ProductSales
ORDER BY TotalQuantity DESC, TotalRevenue DESC;
GO


---------------------------------------------------------------
-- BUSINESS QUESTION (1 st)
---------------------------------------------------------------

-- Business question: Customers with unpaid orders (risk / follow-up)
SELECT
    c.CustomerID,
    c.Fullname,
    c.Email,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    p.PaymentStatus
FROM dbo.Customers c
JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
LEFT JOIN dbo.Payments p ON p.OrderID = o.OrderID
WHERE (p.PaymentStatus IS NULL OR p.PaymentStatus <> 'Paid')
ORDER BY o.OrderDate DESC;
GO
