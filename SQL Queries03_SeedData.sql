INSERT INTO dbo.Customers (Email, Fullname, Phone)
VALUES
('anna.andersson@gmail.com','Anna Andersson','0701112233'),
('erik.nilsson@gmail.com','Erik Nilsson','0701112234'),
('sara.lind@gmail.com','Sara Lind','0701112235'),
('johan.berg@gmail.com','Johan Berg','0701112236'),
('emma.svensson@gmail.com','Emma Svensson','0701112237'),
('oskar.karlsson@gmail.com','Oskar Karlsson','0701112238'),
('lisa.holm@gmail.com','Lisa Holm','0701112239'),
('daniel.persson@gmail.com','Daniel Persson','0701112240'),
('elin.ek@gmail.com','Elin Ek','0701112241'),
('fredrik.larsson@gmail.com','Fredrik Larsson','0701112242'),

('maria.jonsson@gmail.com','Maria Jonsson','0701112243'),
('alex.paulsen@gmail.com','Alex Paulsen','0701112244'),
('sofie.nord@gmail.com','Sofie Nord','0701112245'),
('markus.ahl@gmail.com','Markus Ahl','0701112246'),
('nina.strom@gmail.com','Nina Ström','0701112247'),
('oliver.lund@gmail.com','Oliver Lund','0701112248'),
('karin.blom@gmail.com','Karin Blom','0701112249'),
('viktor.hed@gmail.com','Viktor Hed','0701112250'),
('ida.rosen@gmail.com','Ida Rosén','0701112251'),
('samuel.eng@gmail.com','Samuel Eng','0701112252'),

('hanna.west@gmail.com','Hanna West','0701112253'),
('anton.fors@gmail.com','Anton Fors','0701112254'),
('petra.dahl@gmail.com','Petra Dahl','0701112255'),
('robin.sund@gmail.com','Robin Sund','0701112256'),
('julia.aker@gmail.com','Julia Åker','0701112257'),
('emil.back@gmail.com','Emil Bäck','0701112258'),
('agnes.lindberg@gmail.com','Agnes Lindberg','0701112259'),
('jonas.krok@gmail.com','Jonas Krok','0701112260'),
('therese.wall@gmail.com','Therese Wall','0701112261'),
('leo.falk@gmail.com','Leo Falk','0701112262');

INSERT INTO dbo.Categories (Name)
VALUES
('Shoes'),
('Clothing'),
('Accessories'),
('Sportswear'),
('Outdoor'),
('Bags'),
('Electronics'),
('Home'),
('Sale'),
('New Arrivals');

INSERT INTO dbo.Products (Name, SKU, Price, IsActive)
VALUES
('Running Shoes Pro','SKU-1001',1299,1),
('Casual Sneakers','SKU-1002',899,1),
('Leather Boots','SKU-1003',1599,1),
('Training T-Shirt','SKU-2001',299,1),
('Hoodie Classic','SKU-2002',599,1),
('Winter Jacket','SKU-2003',1799,1),
('Baseball Cap','SKU-3001',199,1),
('Wool Scarf','SKU-3002',349,1),
('Sports Socks 5-pack','SKU-3003',149,1),
('Gym Bag','SKU-4001',699,1),

('Backpack 25L','SKU-4002',899,1),
('Travel Duffel','SKU-4003',1099,1),
('Smart Water Bottle','SKU-5001',249,1),
('Yoga Mat','SKU-5002',399,1),
('Resistance Bands','SKU-5003',299,1),
('Wireless Earbuds','SKU-6001',1499,1),
('Fitness Watch','SKU-6002',2499,1),
('Bluetooth Speaker','SKU-6003',1299,1),
('LED Desk Lamp','SKU-7001',499,1),
('Coffee Mug','SKU-7002',199,1),

('Throw Blanket','SKU-7003',599,1),
('Sneaker Cleaner Kit','SKU-8001',249,1),
('Rain Jacket','SKU-2004',1399,1),
('Trail Running Shoes','SKU-1004',1499,1),
('Compression Tights','SKU-2005',499,1),
('Sports Bra','SKU-2006',449,1),
('Beanie Hat','SKU-3004',199,1),
('Outdoor Gloves','SKU-3005',349,1),
('Old Season Jacket','SKU-9001',999,0),
('Clearance Sneakers','SKU-9002',699,0);

INSERT INTO dbo.Inventory (ProductID, StockQuantity)
SELECT ProductID,
       CASE 
         WHEN ProductID % 5 = 0 THEN 0
         WHEN ProductID % 3 = 0 THEN 10
         ELSE 25
       END
FROM dbo.Products;

INSERT INTO dbo.ProductCategories (ProductID, CategoryID)
SELECT p.ProductID, c.CategoryID
FROM dbo.Products p
JOIN dbo.Categories c
ON
(
   (p.Name LIKE '%Shoes%' AND c.Name = 'Shoes')
OR (p.Name LIKE '%Jacket%' AND c.Name IN ('Clothing','Outdoor'))
OR (p.Name LIKE '%Bag%' AND c.Name = 'Bags')
OR (p.Name LIKE '%Sports%' AND c.Name IN ('Sportswear','New Arrivals'))
OR (p.IsActive = 0 AND c.Name = 'Sale')
);


DECLARE @i INT = 1;
DECLARE @CustomerId INT;
DECLARE @ProductId INT;
DECLARE @OrderId INT;

WHILE @i <= 30
BEGIN
    SELECT TOP 1 @CustomerId = CustomerID FROM dbo.Customers ORDER BY NEWID();
    SELECT TOP 1 @ProductId = ProductID FROM dbo.Products WHERE IsActive = 1 ORDER BY NEWID();

    INSERT INTO dbo.Orders (CustomerID, Status, TotalAmount)
    VALUES (@CustomerId, 'Paid', 0);

    SET @OrderId = SCOPE_IDENTITY();

    INSERT INTO dbo.OrderItems (OrderID, ProductID, Quantity, UnitPrice, LineTotal)
    SELECT
        @OrderId,
        @ProductId,
        1,
        Price,
        Price
    FROM dbo.Products
    WHERE ProductID = @ProductId;

    UPDATE dbo.Orders
    SET TotalAmount = (SELECT SUM(LineTotal) FROM dbo.OrderItems WHERE OrderID = @OrderId)
    WHERE OrderID = @OrderId;

    INSERT INTO dbo.Payments (OrderID, PaymentOption, Amount, PaymentStatus, PaidAt)
    VALUES (@OrderId, 'Card',
            (SELECT TotalAmount FROM dbo.Orders WHERE OrderID=@OrderId),
            'Paid',
            SYSUTCDATETIME());

    SET @i += 1;
END;
GO


SELECT 'Customers', COUNT(*) FROM dbo.Customers
UNION ALL SELECT 'Categories', COUNT(*) FROM dbo.Categories
UNION ALL SELECT 'Products', COUNT(*) FROM dbo.Products
UNION ALL SELECT 'Inventory', COUNT(*) FROM dbo.Inventory
UNION ALL SELECT 'ProductCategories', COUNT(*) FROM dbo.ProductCategories
UNION ALL SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL SELECT 'OrderItems', COUNT(*) FROM dbo.OrderItems
UNION ALL SELECT 'Payments', COUNT(*) FROM dbo.Payments;
