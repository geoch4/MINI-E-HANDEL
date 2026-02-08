USE MiniehandelDB;
GO

/* SELECT - CRUD examples */

-- 1) All customers (latest first)
SELECT CustomerID, Fullname, Email, Phone, CreatedAt
FROM dbo.Customers
ORDER BY CreatedAt DESC;

-- 2) Active products sorted by price (highest first)
SELECT ProductID, Name, SKU, Price
FROM dbo.Products
WHERE IsActive = 1
ORDER BY Price DESC;

-- 3) Top 5 most expensive active products
SELECT TOP (5) ProductID, Name, SKU, Price
FROM dbo.Products
WHERE IsActive = 1
ORDER BY Price DESC;

-- 4) Orders (basic)
SELECT OrderID, CustomerID, Status, OrderDate, TotalAmount
FROM dbo.Orders
ORDER BY OrderDate DESC;

-- 5) Customers + number of orders (including 0 orders)
SELECT
    c.CustomerID,
    c.Fullname,
    COUNT(o.OrderID) AS OrderCount
FROM dbo.Customers c
LEFT JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Fullname
ORDER BY OrderCount DESC;

-- 6) Customers with more than 2 orders (HAVING)
SELECT
    c.Fullname,
    COUNT(o.OrderID) AS OrderCount
FROM dbo.Customers c
JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.Fullname
HAVING COUNT(o.OrderID) > 2
ORDER BY OrderCount DESC;
GO
