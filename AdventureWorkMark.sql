--------------------------------------------------------------------------------------------------------------------------
SELECT	top (100) *
FROM adventurework.dbo.Customers 			
			--Combine first name - last name by using concat ( + , + )--
Select	concat(Prefix, FirstName, LastName) as Name
FROM dbo.Customers

			--MaritalStatus
select	trim(concat(Prefix, FirstName, LastName)) as Full_Name,
		MaritalStatus
from dbo.Customers

			-- Single male/female that having children
select	MaritalStatus, 
		count(CustomerKey) as Total_people,sum(TotalChildren) as Total_Children,
		Gender
from dbo.Customers
where Gender not in ('NA')
group by MaritalStatus,Gender

--------------------------------------------------------------------------------------------------------------------------
							--ProductTable
WITH revenue AS 
(
select	
		ProductSubcategoryKey,
		count(ProductKey) as Total_Orders,
		SUM(ProductCost) as Sum_ProductCost,
		SUM(ProductPrice) as Sum_SellingPrice,
		(SUM(ProductPrice) * count(ProductKey)) - (SUM(ProductCost)) as Revenue
FROM dbo.Products
WHERE ProductSubcategoryKey is not null
Group by ProductSubcategoryKey
)
select	r.ProductSubcategoryKey,
		ps.SubcategoryName,
		cs.CategoryName,
		sum(r.Total_Orders) as Total_Orders,
		SUM(r.Sum_ProductCost) as Sum_ProductCost,
		SUM(r.Sum_SellingPrice) as Sum_SellingPrice,
		SUM(r.Revenue) as Predicted_Revenue
From revenue r
JOIN	dbo.Product_Subcategories ps
	ON ps.ProductSubcategoryKey = r.ProductSubcategoryKey
JOIN	dbo.Product_Categories cs
	ON cs.ProductCategoryKey = ps.ProductCategoryKey
Group by r.ProductSubcategoryKey, ps.SubcategoryName,ps.ProductCategoryKey,cs.CategoryName;

--------------------------------------------------------------------------------------------------------------------------
					-- Sales in Three Years w Customer
WITH SalesInThreeYears AS
(
    SELECT *
    FROM dbo.Sales_2015
    UNION
    SELECT *
    FROM dbo.Sales_2016
    UNION
    SELECT *
    FROM dbo.Sales_2017
),
Cleaned_Data AS
(
    SELECT
        sity.ProductKey,
        sity.CustomerKey,
        TRIM(CONCAT(c.Prefix, c.FirstName, c.LastName)) AS Full_Name,
        p.ProductName,
		ps.SubcategoryName,
		pc.CategoryName,
        sity.OrderNumber,
        CAST(sity.OrderDate AS DATE) AS Ship_Date,
        CAST(rs.ReturnDate AS DATE) AS Return_Date,
        sity.TerritoryKey,
        t.Country, t.Continent,
        sity.OrderQuantity,
        p.ProductPrice,
        ROW_NUMBER() OVER (PARTITION BY sity.ProductKey, sity.CustomerKey, sity.TerritoryKey, p.ProductName ORDER BY sity.ProductKey) AS Row_Num
    FROM SalesInThreeYears sity
		LEFT JOIN dbo.Returns rs ON (sity.TerritoryKey = rs.TerritoryKey) AND (rs.ProductKey = sity.ProductKey)
		LEFT JOIN dbo.Customers c ON c.CustomerKey = sity.CustomerKey
		LEFT JOIN dbo.Products p ON sity.ProductKey = p.ProductKey
		LEFT JOIN dbo.Territories t ON sity.TerritoryKey = t.SalesTerritoryKey
		LEFT JOIN dbo.Product_Subcategories ps ON  p.ProductSubCategoryKey = ps.ProductSubcategoryKey
		LEFT JOIN dbo.Product_Categories pc ON ps.ProductCategoryKey = pc.ProductCategoryKey 
    WHERE sity.OrderDate < rs.ReturnDate
)
SELECT
    --ProductKey,
    CustomerKey,
    Full_Name,
    ProductName,
	SubcategoryName,
	CategoryName,
	OrderNumber,
    Ship_Date,
    Return_Date,
    TerritoryKey,
    Country, Continent,
    sum(OrderQuantity) as Total_Orders,
    (sum(ProductPrice) * sum(OrderQuantity)) as Profit
FROM Cleaned_Data
WHERE Row_Num = 1 
GROUP BY	--ProductKey,	
			CustomerKey,
			Full_Name,
			ProductName,
			SubcategoryName,
			CategoryName,
			OrderNumber,
			Ship_Date,
			Return_Date,
			TerritoryKey,
			Country, Continent
ORDER BY Ship_Date ASC;

--------------------------------------------------------------------------------------------------------------------------

