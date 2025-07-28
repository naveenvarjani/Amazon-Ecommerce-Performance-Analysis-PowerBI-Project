#14. Top Customers Based on Custom Score

WITH newtable AS (
    SELECT 
        customer_id,
        SUM(unit_price * order_qty) AS total_spent,
        COUNT(order_id) AS order_count,
        AVG(unit_price * order_qty) AS avg_spent
    FROM orders
    GROUP BY customer_id
)
SELECT 
    customer_id,
    (0.5 * total_spent + 0.3 * order_count + 0.2 * avg_spent) AS score
FROM newtable
ORDER BY score DESC
LIMIT 5;

#15. Monthly Revenue Growth Analysis

WITH newtable AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS yearmonth,
        SUM(sale_price) AS revenue
    FROM orders
    GROUP BY yearmonth
)
SELECT 
    yearmonth,
    LAG(revenue, 1) OVER (ORDER BY yearmonth) AS revenue_last_month,
    revenue AS revenue_this_month,
    ROUND(
        (revenue - LAG(revenue, 1) OVER (ORDER BY yearmonth)) /
        LAG(revenue, 1) OVER (ORDER BY yearmonth) * 100, 2
    ) AS growth
FROM newtable;

#16. 3-Month Rolling Average by Category

WITH newtable AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS yearmonth,
        category,
        SUM(sale_price) AS revenue
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m'), category
)
SELECT 
    yearmonth,
    category,
    AVG(revenue) OVER (
        PARTITION BY category
        ORDER BY yearmonth
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) AS rolling_average
FROM newtable;

#17. Update Discount for Loyal Customers

UPDATE orders
SET sale_price = sale_price * 0.15
WHERE customer_id IN (
    SELECT customer_id
    FROM (
        SELECT customer_id
        FROM orders
        GROUP BY customer_id
        HAVING COUNT(order_id) >= 10
    ) AS temp
);

#18. Average Days Between Orders (Loyal Customers)

WITH cte AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order
    FROM orders
)
SELECT 
    customer_id, 
    AVG(DATEDIFF(order_date, next_order)) AS avg_difference 
FROM cte
WHERE next_order IS NOT NULL
GROUP BY customer_id
HAVING COUNT(order_id) >= 5;

#19. High Revenue Customers (Above 30% of Avg Sale)

WITH cte AS (
    SELECT customer_id, SUM(sale_price) AS revenue 
    FROM orders
    GROUP BY customer_id
)
SELECT customer_id, revenue 
FROM cte
WHERE revenue > (
    SELECT AVG(sale_price) + AVG(sale_price) * 0.3 FROM orders
)
ORDER BY revenue DESC;

#20. Top 3 Categories with Highest Sales Growth (Year-on-Year)

WITH current_year AS (
    SELECT category, SUM(sale_price) AS sales 
    FROM orders
    WHERE YEAR(order_date) = 2020
    GROUP BY category
),
previous_year AS (
    SELECT category, SUM(sale_price) AS sales 
    FROM orders
    WHERE YEAR(order_date) = 2019
    GROUP BY category
)
SELECT 
    c.category,
    c.sales AS current_year_sale,
    p.sales AS previous_year_sale,
    c.sales - p.sales AS sales_diff
FROM current_year c
JOIN previous_year p ON c.category = p.category
ORDER BY sales_diff DESC
LIMIT 3;
