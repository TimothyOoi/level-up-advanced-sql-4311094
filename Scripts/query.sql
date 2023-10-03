select *
from employee limit 5;

select sql 
from sqlite_schema
where name='employee';


-- self-join
select 
  e.firstName,
  e.lastName,
  e.title,
  m.firstName as ManagerFirstName,
  m.lastName as ManagerLastName
from employee e JOIN employee m
ON e.managerId =m.employeeId;

-- salespeople with 0 sales
SELECT 
  e.employeeId,
  e.firstName || ' ' || e.lastName as employeeName,
  e.title
FROM employee e LEFT JOIN sales s ON e.employeeId=s.employeeId
WHERE e.title='Sales Person' AND s.salesId IS NULL;


-- get list of all sales and customers
(
  SELECT C.firstName, c.lastName, c.email,s.salesAmount, s.soldDate
  FROM sales s JOIN customer c ON S.customerId=C.customerId
)
UNION
(
  SELECT C.firstName, c.lastName, c.email,s.salesAmount, s.soldDate
  FROM sales s LEFT JOIN customer c ON S.customerId=C.customerId
  WHERE c.customerId IS NULL
)
UNION
(
  SELECT C.firstName, c.lastName, c.email,s.salesAmount, s.soldDate
  FROM customer c LEFT JOIN sales s ON S.customerId=C.customerId
  WHERE s.salesId IS NULL
)

-- no. of cars sold by each employee
SELECT
  e.employeeId,
  e.firstName,
  e.lastName,
  COUNT(salesId) AS totalCarsSold
FROM employee e JOIN sales s ON e.employeeId=s.employeeId
GROUP BY e.employeeId
ORDER BY totalCarsSold DESC;

-- find the least and most expensive cars sold by each employee this year
SELECT
  e.employeeId,
  e.firstName,
  e.lastName,
  MIN(s.salesAmount) AS lowestPrice,
  MAX(s.salesAmount) AS highestPrice
FROM employee e JOIN sales s ON e.employeeId=s.employeeId
-- WHERE s.soldDate >= '2022-01-01'
WHERE s.soldDate >= DATE('now', 'start of year')
GROUP BY e.employeeId, e.firstName, e.lastName;

-- employees who made more than 5 sales this year
SELECT
  e.employeeId,
  e.firstName,
  e.lastName,
  COUNT(s.salesId) as totalSales
FROM employee e JOIN sales s ON e.employeeId=s.employeeId
WHERE s.soldDate >= DATE('now', 'start of year')
GROUP BY e.employeeId, e.firstName, e.lastName
HAVING COUNT(s.salesId) > 5;

-- sales per year
WITH cte AS (
  SELECT 
    salesAmount,
    strftime('%Y', sales.soldDate) as year
  FROM sales
)
select year, FORMAT('$%.2f', sum(salesAmount)) as totalSalesAmount
from cte
group by year
order by year;

select * from sales;

-- sales per employee for each month in 2021
WITH cte AS (
  SELECT strftime('%m', sales.soldDate) as month, sales.salesAmount, sales.employeeId
  FROM sales
  WHERE sales.soldDate >= '2021-01-01' AND sales.soldDate <= '2022-01-01'
)
SELECT
  e.firstName,
  e.lastName,
  SUM(CASE WHEN month='01' THEN salesAmount END) as 'Jan 2021',
  SUM(CASE WHEN month='02' THEN salesAmount END) as 'Feb 2021',
  SUM(CASE WHEN month='03' THEN salesAmount END) as 'Mar 2021',
  SUM(CASE WHEN month='04' THEN salesAmount END) as 'Apr 2021',
  SUM(CASE WHEN month='05' THEN salesAmount END) as 'May 2021',
  SUM(CASE WHEN month='06' THEN salesAmount END) as 'Jun 2021',
  SUM(CASE WHEN month='07' THEN salesAmount END) as 'Jul 2021',
  SUM(CASE WHEN month='08' THEN salesAmount END) as 'Aug 2021',
  SUM(CASE WHEN month='09' THEN salesAmount END) as 'Sep 2021',
  SUM(CASE WHEN month='10' THEN salesAmount END) as 'Oct 2021',
  SUM(CASE WHEN month='11' THEN salesAmount END) as 'Nov 2021',
  SUM(CASE WHEN month='12' THEN salesAmount END) as 'Dec 2021'
FROM employee e JOIN cte s ON e.employeeId=s.employeeId
GROUP BY e.firstName, e.lastName
ORDER BY e.lastName, e.firstName;


-- find sales of electric cars
SELECT s.salesId, m.modelId, m.EngineType
FROM sales s join inventory i on s.inventoryId=i.inventoryId JOIN model m ON i.modelId=m.modelId
WHERE m.EngineType='Electric';

SELECT s.salesId, s.soldDate, s.salesAmount
FROM sales s JOIN inventory i ON s.inventoryId=i.inventoryId
WHERE i.modelId IN (SELECT modelId FROM model WHERE EngineType='Electric');


-- get list of sales people and rank the car models they've sold the most
SELECT
  e.employeeid,
  e.firstname, 
  e.lastname, 
  count(i.modelId) as numberSold,
  RANK() OVER(PARTITION BY s.employeeId ORDER BY count(i.modelId) DESC) AS numUniqueModels
FROM employee e JOIN sales s ON e.employeeid=s.employeeId JOIN inventory i on s.inventoryId=i.inventoryId
GROUP BY e.employeeid, e.firstname, e.lastname, I.modelId;

-- sales per month and annual running total**
WITH cte AS (
  SELECT 
    strftime('%Y', soldDate) as soldYear,
    strftime('%m', soldDate) as soldMonth,
    SUM(salesAmount) as totalSales
  FROM sales
  GROUP by soldYear, soldMonth
)
SELECT
   soldYear, soldMonth, totalSales,
   SUM(totalSales) OVER(PARTITION BY soldYear ORDER BY soldYear, soldMonth) as annualRunningTotal
FROM cte;

-- no. cars sold this month and last month
WITH cte AS (
  SELECT 
    strftime('%Y', soldDate) as soldYear,
    strftime('%m', soldDate) as soldMonth,
    COUNT(salesId) as totalSales
  FROM sales
  GROUP by soldYear, soldMonth
) 
SELECT
  soldYear, soldMonth, totalSales as isMonthTotalSold,
  LAG(totalSales) OVER(ORDER BY soldYear, soldMonth) as lastMonthTotalSold
FROM cte
ORDER BY soldYear, soldMonth;