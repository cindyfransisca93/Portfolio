/*
Dataquest Premium Guided Project: Customers and Products Analysis Using SQL
Goal: To analyze data from a sales records database ('stores' db) for a hypothetical cars company and extract information for decision-making.

Skills used: Joins, CTE's, Aggregate Functions
*/

-- Create a file named 'project.sql' where you can write all the project queries.

-- Provide a brief description of what each table contains.

-- 'customers' : contact information of registered customers
-- 'employees' : contact information & reporting line of registered employees
-- 'offices' : location information of registered office branches
-- 'orders' : date and status of registered orders placed by customers 
-- 'orderdetails' : product information of registered orders placed by customers 
-- 'payments' : amount, dates, and customer information of registered payments made to the company
-- 'products' : product information and origin details of the inventory 
-- 'productlines' : description and image of product categories

-- Display the name, num of columns, and num of rows of each table in the 'stores' schema.

WITH
row_count AS (
		SELECT 'customers' AS table_name, COUNT(*) AS number_of_rows
		FROM customers
			UNION ALL
		SELECT 'employees', COUNT(*)
		FROM employees
			UNION ALL
		SELECT 'offices', COUNT(*)
		FROM offices
			UNION ALL
		SELECT 'orderdetails', COUNT(*)
		FROM orderdetails
			UNION ALL
		SELECT 'orders', COUNT(*)
		FROM orders
			UNION ALL
		SELECT 'payments', COUNT(*)
		FROM payments
			UNION ALL
		SELECT 'products', COUNT(*)
		FROM products
)

				  SELECT m.name AS table_name, 
					             COUNT(*) AS number_of_attributes,
						          r.number_of_rows
					  FROM sqlite_master m
LEFT OUTER JOIN pragma_table_info(m.name) p
						   ON m.name <> p.name
			  LEFT JOIN row_count AS r
						   ON m.name = r.table_name
				   WHERE m.type = 'table'
		     GROUP BY m.name;
		  
-- 4. Write two queries to optimize product restocking.

-- Dsplay the top 10 of low-in-stock products & the top 10 products based on product sales

WITH

prod_perf AS (
		SELECT productCode,
					   SUM (quantityOrdered) AS ordered,
					   SUM (quantityOrdered * priceEach) AS product_sales
		FROM orderdetails 
		GROUP BY productCode
		ORDER BY product_sales DESC
		LIMIT 10
),

-- Note: the guided project specifically uses the 'low stock' criteria defined as the 10 products with the lowest SUM(quantityOrdered)/quantityInStock.
-- My personal opinion says that,
-- a) although a company is assumed to be free to define the metric as they wish, the 'ordered/instock' approach is a less intuitive metric
-- especially when the ultimate goal is said to "prevent the best-selling products from going out-of-stock."
-- my preferred definition is "the 10 lowest of instock/AVG(quantityOrdered)"
-- because I believe frequency/timing plays a big factor in inventory decisions--priority should be given to products more likely to go out of stock in the next few immediate orders
-- b) even if we agree with the metrics, the use of '10 lowest' is a mismatch of solution, as it is more appropriate to use 10 highest.  

-- For the purpose of this project I will go with the 10 products with the highest SUM(quantityOrdered)/quantityInStock

low_stock AS (
		SELECT pp.productCode,
					   ROUND(SUM(pp.ordered)/p.quantityInStock,2) AS low_stock_rate
		FROM prod_perf pp
		JOIN products p
		ON p.productCode = pp.productCode
		GROUP BY pp.productCode
		ORDER BY low_stock_rate DESC
		LIMIT 10
)
			 
-- Display the top performing products currently low-in-stock:
			 
		SELECT 	 ls.productCode,
						 p.productName,
						 p.productLine,
						 ls.low_stock_rate,
						 (SELECT pp.product_sales
							  FROM prod_perf pp) AS product_sales
		FROM low_stock ls
		JOIN products p
		   ON ls.productCode = p.productCode
		WHERE ls.productCode IN ( SELECT pp.productCode
													   FROM prod_perf pp)
	
-- 5. Write queries to optimize customer engagement
-- Calculate profit per customer & determine their VIP vs least engaged status.

WITH
cust_profit AS (
				  SELECT o.customerNumber, 
								 SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
					  FROM products p
LEFT OUTER JOIN orderdetails od
						   ON p.productCode = od.productCode
LEFT OUTER JOIN orders o
						   ON od.orderNumber = o.orderNumber
			 GROUP BY o.customerNumber
),
			 
cust_vip AS (
			SELECT contactLastName,
							contactFirstName,
							city,
							country,
							profit
				FROM cust_profit
		LEFT JOIN customers c
					 ON c.customerNumber = cust_profit.customerNumber
	   ORDER BY profit DESC
),

cust_least    AS (
			SELECT contactLastName,
							contactFirstName,
							city,
							country,
							profit
				FROM cust_profit
		LEFT JOIN customers c
					 ON c.customerNumber = cust_profit.customerNumber
			 WHERE contactFirstName IS NOT NULL
	   ORDER BY profit ASC
)				 

-- Top 5 VIP customers:
	   
	SELECT * 
	FROM cust_vip
	LIMIT 5;

-- Top 5 least engaged customers:
	
	SELECT * 
	FROM cust_least
	LIMIT 5;
	
-- 6. Analyze the number of new customers arriving each month

WITH

payment_with_year_month_table AS (
		SELECT *, 
						CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
		   FROM payments p
),

customers_by_month_table AS (
	  SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
          FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(*) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_sales_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS sales_total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
)

-- Display how many new customers & how much sales came from new customers, against total customers & total sales, on a monthly basis

SELECT year_month, 
				ROUND(number_of_new_customers*100/number_of_customers,1) AS pct_number_of_new_customers,
				ROUND(new_customer_sales_total*100/sales_total,1) AS pct_new_customers_sales_total
    FROM new_customers_by_month_table;
  
-- 7. Write a query to compute the Customer Lifetime Value (LTV), or the average amount of money generated per customer.

-- Based on the cust_profit CTE:

	SELECT AVG(profit) as avg_profit
	FROM cust_profit cp