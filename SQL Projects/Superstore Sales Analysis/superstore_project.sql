-- ============================================================
--   SUPERSTORE SALES ANALYTICS — SQL PROJECT
-- ============================================================


-- ============================================================
--  SECTION 1 — CREATE TABLE & LOAD DATA
-- ============================================================

CREATE DATABASE IF NOT EXISTS superstore;
USE superstore;

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    row_id       INT PRIMARY KEY,
    order_id     VARCHAR(20),
    order_date   DATE,
    ship_date    DATE,
    ship_mode    VARCHAR(20),
    customer_id  VARCHAR(10),
    customer_name VARCHAR(50),
    segment      VARCHAR(20),
    country      VARCHAR(30),
    city         VARCHAR(50),
    state        VARCHAR(30),
    postal_code  VARCHAR(10),
    region       VARCHAR(10),
    product_id   VARCHAR(20),
    category     VARCHAR(25),
    sub_category VARCHAR(20),
    product_name VARCHAR(200),
    sales        DECIMAL(10,4),
    quantity     INT,
    discount     DECIMAL(5,2),
    profit       DECIMAL(10,4)
);


-- ============================================================
--  SECTION 2 — BASIC EXPLORATION
-- ============================================================

-- Q1. Total number of records in the dataset
SELECT COUNT(*) AS total_records FROM orders;

-- Q2. Date range of the dataset
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS days_span
FROM orders;

-- Q3. Unique counts for key dimensions
SELECT
    COUNT(DISTINCT order_id)    AS unique_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id)  AS unique_products,
    COUNT(DISTINCT state)       AS unique_states
FROM orders;

-- Q4. Revenue, profit, and quantity overview
SELECT
    ROUND(SUM(sales),   2) AS total_revenue,
    ROUND(SUM(profit),  2) AS total_profit,
    ROUND(AVG(sales),   2) AS avg_order_value,
    ROUND(AVG(profit),  2) AS avg_profit,
    SUM(quantity)          AS total_units_sold
FROM orders;

-- Q5. All distinct segments, categories, regions, and ship modes
SELECT DISTINCT segment    FROM orders ORDER BY segment;
SELECT DISTINCT category   FROM orders ORDER BY category;
SELECT DISTINCT region     FROM orders ORDER BY region;
SELECT DISTINCT ship_mode  FROM orders ORDER BY ship_mode;


-- ============================================================
--  SECTION 3 — SALES & REVENUE ANALYSIS
-- ============================================================

-- Q6. Total sales and profit by category
SELECT
    category,
    ROUND(SUM(sales),  2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY category
ORDER BY total_sales DESC;

-- Q7. Top 10 sub-categories by revenue
SELECT
    sub_category,
    ROUND(SUM(sales),    2) AS total_sales,
    ROUND(SUM(profit),   2) AS total_profit,
    SUM(quantity)           AS units_sold
FROM orders
GROUP BY sub_category
ORDER BY total_sales DESC
LIMIT 10;

-- Q8. Monthly sales trend (year-wise)
SELECT
    YEAR(order_date)  AS yr,
    MONTH(order_date) AS mo,
    MONTHNAME(order_date) AS month_name,
    ROUND(SUM(sales),  2) AS monthly_sales,
    ROUND(SUM(profit), 2) AS monthly_profit
FROM orders
GROUP BY yr, mo, month_name
ORDER BY yr, mo;

-- Q9. Which year had the highest revenue?
SELECT
    YEAR(order_date) AS yr,
    ROUND(SUM(sales),  2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY yr
ORDER BY total_sales DESC;

-- Q10. Sales by region and category (pivot-style)
SELECT
    region,
    ROUND(SUM(CASE WHEN category = 'Furniture'       THEN sales ELSE 0 END), 2) AS furniture_sales,
    ROUND(SUM(CASE WHEN category = 'Office Supplies' THEN sales ELSE 0 END), 2) AS office_sales,
    ROUND(SUM(CASE WHEN category = 'Technology'      THEN sales ELSE 0 END), 2) AS tech_sales,
    ROUND(SUM(sales), 2) AS total_sales
FROM orders
GROUP BY region
ORDER BY total_sales DESC;


-- ============================================================
--  SECTION 4 — PROFIT ANALYSIS
-- ============================================================

-- Q11. The most and least profitable sub-categories
SELECT
    sub_category,
    ROUND(SUM(profit), 2)  AS total_profit,
    ROUND(AVG(profit), 2)  AS avg_profit_per_order,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct
FROM orders
GROUP BY sub_category
ORDER BY total_profit DESC;

-- Q12. Sub-categories running at a net LOSS
SELECT
    sub_category,
    ROUND(SUM(sales),  2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY sub_category
HAVING total_profit < 0
ORDER BY total_profit;

-- Q13. Impact of discounts on profit
SELECT
    CASE
        WHEN discount = 0          THEN 'No Discount'
        WHEN discount BETWEEN 0.01 AND 0.10 THEN 'Low (1-10%)'
        WHEN discount BETWEEN 0.11 AND 0.30 THEN 'Medium (11-30%)'
        ELSE 'High (>30%)'
    END AS discount_bucket,
    COUNT(*)                       AS num_orders,
    ROUND(AVG(profit), 2)          AS avg_profit,
    ROUND(SUM(profit), 2)          AS total_profit
FROM orders
GROUP BY discount_bucket
ORDER BY avg_profit DESC;

-- Q14. Orders where discount caused a loss
SELECT
    order_id, product_name, sales,
    discount, ROUND(profit, 2) AS profit
FROM orders
WHERE profit < 0 AND discount > 0
ORDER BY profit
LIMIT 20;

-- Q15. Profit by customer segment
SELECT
    segment,
    COUNT(DISTINCT order_id)      AS total_orders,
    ROUND(SUM(sales),  2)         AS total_sales,
    ROUND(SUM(profit), 2)         AS total_profit,
    ROUND(AVG(sales),  2)         AS avg_order_value
FROM orders
GROUP BY segment
ORDER BY total_profit DESC;


-- ============================================================
--  SECTION 5 — CUSTOMER ANALYSIS
-- ============================================================

-- Q16. Top 10 customers by total revenue
SELECT
    customer_id,
    customer_name,
    segment,
    COUNT(DISTINCT order_id)  AS total_orders,
    ROUND(SUM(sales),  2)     AS total_spent,
    ROUND(SUM(profit), 2)     AS profit_generated
FROM orders
GROUP BY customer_id, customer_name, segment
ORDER BY total_spent DESC
LIMIT 10;

-- Q17. Customers who have placed only 1 order (one-time buyers)
SELECT
    customer_id,
    customer_name,
    segment,
    ROUND(SUM(sales), 2) AS total_spent
FROM orders
GROUP BY customer_id, customer_name, segment
HAVING COUNT(DISTINCT order_id) = 1
ORDER BY total_spent DESC;

-- Q18. Most loyal customers (highest number of orders)
SELECT
    customer_name,
    segment,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales),  2)    AS lifetime_value
FROM orders
GROUP BY customer_id, customer_name, segment
ORDER BY total_orders DESC
LIMIT 10;

-- Q19. Average number of orders per customer
SELECT
    ROUND(COUNT(DISTINCT order_id) / COUNT(DISTINCT customer_id), 2)
    AS avg_orders_per_customer
FROM orders;

-- Q20. Customer distribution by segment and region
SELECT
    region,
    segment,
    COUNT(DISTINCT customer_id) AS num_customers
FROM orders
GROUP BY region, segment
ORDER BY region, num_customers DESC;


-- ============================================================
--  SECTION 6 — PRODUCT ANALYSIS
-- ============================================================

-- Q21. Top 10 best-selling products by revenue
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales),  2) AS total_sales,
    SUM(quantity)         AS total_units
FROM orders
GROUP BY product_id, product_name, category, sub_category
ORDER BY total_sales DESC
LIMIT 10;

-- Q22. Top 10 most profitable products
SELECT
    product_name,
    category,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(sales),  2) AS total_sales
FROM orders
GROUP BY product_id, product_name, category
ORDER BY total_profit DESC
LIMIT 10;

-- Q23. Products that have NEVER generated profit
SELECT
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales),  2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY product_id, product_name, category, sub_category
HAVING total_profit < 0
ORDER BY total_profit
LIMIT 15;

-- Q24. Products ordered just once
SELECT
    product_name,
    category,
    COUNT(*) AS times_ordered
FROM orders
GROUP BY product_id, product_name, category
HAVING times_ordered = 1;

-- Q25. Average sales per unit (unit price proxy) by sub-category
SELECT
    sub_category,
    ROUND(AVG(sales / quantity), 2) AS avg_unit_price,
    ROUND(MIN(sales / quantity), 2) AS min_unit_price,
    ROUND(MAX(sales / quantity), 2) AS max_unit_price
FROM orders
GROUP BY sub_category
ORDER BY avg_unit_price DESC;


-- ============================================================
--  SECTION 7 — SHIPPING & OPERATIONS ANALYSIS
-- ============================================================

-- Q26. Average shipping time (days) by ship mode
SELECT
    ship_mode,
    COUNT(*)                                        AS total_orders,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 1) AS avg_ship_days,
    MIN(DATEDIFF(ship_date, order_date))           AS min_days,
    MAX(DATEDIFF(ship_date, order_date))           AS max_days
FROM orders
GROUP BY ship_mode
ORDER BY avg_ship_days;

-- Q27. Ship mode usage by segment
SELECT
    segment,
    ship_mode,
    COUNT(DISTINCT order_id) AS num_orders,
    ROUND(SUM(sales), 2)     AS total_sales
FROM orders
GROUP BY segment, ship_mode
ORDER BY segment, num_orders DESC;

-- Q28. Orders that took more than 7 days to ship (delayed)
SELECT
    order_id,
    customer_name,
    ship_mode,
    order_date,
    ship_date,
    DATEDIFF(ship_date, order_date) AS days_to_ship,
    ROUND(sales, 2) AS order_value
FROM orders
WHERE DATEDIFF(ship_date, order_date) > 7
ORDER BY days_to_ship DESC
LIMIT 20;

-- Q29. Sales by day of the week (which day gets most orders?)
SELECT
    DAYNAME(order_date)  AS day_of_week,
    COUNT(DISTINCT order_id) AS num_orders,
    ROUND(SUM(sales), 2) AS total_sales
FROM orders
GROUP BY day_of_week
ORDER BY FIELD(day_of_week,
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- Q30. Top 10 states by revenue
SELECT
    state,
    region,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales),  2)    AS total_sales,
    ROUND(SUM(profit), 2)    AS total_profit
FROM orders
GROUP BY state, region
ORDER BY total_sales DESC
LIMIT 10;


-- ============================================================
--  SECTION 8 — ADVANCED QUERIES (WINDOW FUNCTIONS & CTEs)
-- ============================================================

-- Q31. Running total of sales over time (cumulative revenue)
SELECT
    order_date,
    ROUND(SUM(sales), 2) AS daily_sales,
    ROUND(SUM(SUM(sales)) OVER (ORDER BY order_date), 2) AS running_total
FROM orders
GROUP BY order_date
ORDER BY order_date;

-- Q32. Rank customers by total spending within each segment
SELECT
    customer_name,
    segment,
    ROUND(SUM(sales), 2) AS total_spent,
    RANK() OVER (PARTITION BY segment ORDER BY SUM(sales) DESC) AS rank_in_segment
FROM orders
GROUP BY customer_id, customer_name, segment
ORDER BY segment, rank_in_segment
LIMIT 30;

-- Q33. Month-over-month sales growth rate
WITH monthly AS (
    SELECT
        YEAR(order_date)  AS yr,
        MONTH(order_date) AS mo,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM orders
    GROUP BY yr, mo
)
SELECT
    yr, mo, monthly_sales,
    LAG(monthly_sales) OVER (ORDER BY yr, mo) AS prev_month_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (ORDER BY yr, mo))
        / LAG(monthly_sales) OVER (ORDER BY yr, mo) * 100, 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY yr, mo;

-- Q34. Top 3 products per category by profit (using DENSE_RANK)
WITH ranked AS (
    SELECT
        category,
        product_name,
        ROUND(SUM(profit), 2) AS total_profit,
        DENSE_RANK() OVER (
            PARTITION BY category ORDER BY SUM(profit) DESC
        ) AS rnk
    FROM orders
    GROUP BY category, product_id, product_name
)
SELECT category, product_name, total_profit, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;

-- Q35. Customers above average spending (subquery)
SELECT
    customer_name,
    segment,
    ROUND(SUM(sales), 2) AS total_spent
FROM orders
GROUP BY customer_id, customer_name, segment
HAVING total_spent > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(sales) AS customer_total
        FROM orders
        GROUP BY customer_id
    ) AS sub
)
ORDER BY total_spent DESC;

-- Q36. Percentage contribution of each region to total sales
SELECT
    region,
    ROUND(SUM(sales), 2) AS region_sales,
    ROUND(
        SUM(sales) / (SELECT SUM(sales) FROM orders) * 100, 2
    ) AS pct_of_total
FROM orders
GROUP BY region
ORDER BY pct_of_total DESC;

-- Q37. YoY (year-over-year) sales comparison by category
WITH yearly AS (
    SELECT
        YEAR(order_date) AS yr,
        category,
        ROUND(SUM(sales), 2) AS yearly_sales
    FROM orders
    GROUP BY yr, category
)
SELECT
    a.category,
    a.yr              AS current_year,
    a.yearly_sales    AS current_sales,
    b.yearly_sales    AS prev_year_sales,
    ROUND(a.yearly_sales - b.yearly_sales, 2)          AS yoy_change,
    ROUND((a.yearly_sales - b.yearly_sales)
          / b.yearly_sales * 100, 2)                   AS yoy_growth_pct
FROM yearly a
LEFT JOIN yearly b
    ON a.category = b.category AND a.yr = b.yr + 1
WHERE b.yr IS NOT NULL
ORDER BY a.category, a.yr;

-- Q38. Customers who have purchased from all 3 categories
SELECT
    customer_name,
    COUNT(DISTINCT category) AS categories_bought,
    ROUND(SUM(sales), 2)     AS total_spent
FROM orders
GROUP BY customer_id, customer_name
HAVING categories_bought = 3
ORDER BY total_spent DESC;

-- Q39. Highest single-order value per customer
SELECT
    customer_name,
    order_id,
    ROUND(SUM(sales), 2) AS order_value
FROM orders
GROUP BY customer_id, customer_name, order_id
HAVING order_value = (
    SELECT ROUND(SUM(sales), 2)
    FROM orders o2
    WHERE o2.customer_id = orders.customer_id
    GROUP BY o2.order_id
    ORDER BY SUM(sales) DESC
    LIMIT 1
)
ORDER BY order_value DESC
LIMIT 15;

-- Q40. Product name pattern — items with 'HP' or 'Canon' brand
SELECT
    product_name,
    category,
    ROUND(SUM(sales),  2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
WHERE product_name REGEXP 'HP|Canon|Epson|Brother|Logitech'
GROUP BY product_id, product_name, category
ORDER BY total_sales DESC;


-- ============================================================
--  SECTION 9 — VIEWS
-- ============================================================

-- View 1: Category performance summary
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT
    category,
    sub_category,
    COUNT(DISTINCT order_id)             AS total_orders,
    ROUND(SUM(sales),  2)                AS total_sales,
    ROUND(SUM(profit), 2)                AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2) AS profit_margin_pct,
    SUM(quantity)                        AS units_sold
FROM orders
GROUP BY category, sub_category;

SELECT * FROM vw_category_performance ORDER BY total_sales DESC;


-- View 2: Customer lifetime value summary
CREATE OR REPLACE VIEW vw_customer_ltv AS
SELECT
    customer_id,
    customer_name,
    segment,
    region,
    COUNT(DISTINCT order_id)  AS total_orders,
    ROUND(SUM(sales),  2)     AS lifetime_value,
    ROUND(SUM(profit), 2)     AS profit_contributed,
    MIN(order_date)           AS first_order,
    MAX(order_date)           AS last_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS days_as_customer
FROM orders
GROUP BY customer_id, customer_name, segment, region;

SELECT * FROM vw_customer_ltv ORDER BY lifetime_value DESC LIMIT 20;


-- View 3: Regional sales dashboard
CREATE OR REPLACE VIEW vw_regional_dashboard AS
SELECT
    region,
    state,
    YEAR(order_date)             AS yr,
    COUNT(DISTINCT order_id)     AS orders,
    COUNT(DISTINCT customer_id)  AS customers,
    ROUND(SUM(sales),  2)        AS sales,
    ROUND(SUM(profit), 2)        AS profit
FROM orders
GROUP BY region, state, yr;

SELECT * FROM vw_regional_dashboard ORDER BY sales DESC;


-- ============================================================
--  SECTION 10 — STORED PROCEDURES
-- ============================================================

DELIMITER //

-- SP 1: Sales summary for a given year
CREATE PROCEDURE spYearlySummary(IN p_year INT)
BEGIN
    SELECT
        category,
        ROUND(SUM(sales),  2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit,
        SUM(quantity)         AS units_sold,
        COUNT(DISTINCT order_id) AS orders
    FROM orders
    WHERE YEAR(order_date) = p_year
    GROUP BY category
    ORDER BY total_sales DESC;
END //

CALL spYearlySummary(2017);
CALL spYearlySummary(2018);


-- SP 2: Customer order history lookup
CREATE PROCEDURE spCustomerHistory(IN p_customer_name VARCHAR(100))
BEGIN
    SELECT
        order_id,
        order_date,
        ship_mode,
        category,
        product_name,
        ROUND(sales,  2) AS sales,
        ROUND(profit, 2) AS profit
    FROM orders
    WHERE customer_name LIKE CONCAT('%', p_customer_name, '%')
    ORDER BY order_date;
END //

CALL spCustomerHistory('Claire Gute');


-- SP 3: Top N products by region
CREATE PROCEDURE spTopProductsByRegion(IN p_region VARCHAR(20), IN p_limit INT)
BEGIN
    SELECT
        product_name,
        sub_category,
        ROUND(SUM(sales),  2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit
    FROM orders
    WHERE region = p_region
    GROUP BY product_id, product_name, sub_category
    ORDER BY total_sales DESC
    LIMIT p_limit;
END //

CALL spTopProductsByRegion('West', 10);
CALL spTopProductsByRegion('East', 5);


-- SP 4: Profit loss alert — sub-categories with negative profit
CREATE PROCEDURE spProfitLossAlert()
BEGIN
    SELECT
        sub_category,
        ROUND(SUM(sales),  2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit,
        COUNT(*)              AS loss_making_orders
    FROM orders
    WHERE profit < 0
    GROUP BY sub_category
    ORDER BY total_profit;
END //

CALL spProfitLossAlert();

DELIMITER ;


-- ============================================================
--  SECTION 11 — BONUS BUSINESS INSIGHT QUERIES
-- ============================================================

-- B1. RFM-style segmentation (Recency, Frequency, Monetary)
SELECT
    customer_name,
    segment,
    DATEDIFF('2018-12-30', MAX(order_date)) AS recency_days,
    COUNT(DISTINCT order_id)                AS frequency,
    ROUND(SUM(sales), 2)                   AS monetary
FROM orders
GROUP BY customer_id, customer_name, segment
ORDER BY recency_days, frequency DESC, monetary DESC
LIMIT 20;

-- B2. Which ship mode is most used for high-value orders (sales > 1000)?
SELECT
    ship_mode,
    COUNT(*) AS num_high_value_orders,
    ROUND(AVG(sales), 2) AS avg_sales
FROM orders
WHERE sales > 1000
GROUP BY ship_mode
ORDER BY num_high_value_orders DESC;

-- B3. States with negative overall profit (loss-making states)
SELECT
    state,
    region,
    ROUND(SUM(sales),  2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY state, region
HAVING total_profit < 0
ORDER BY total_profit;

-- B4. Percentage of orders that resulted in a loss
SELECT
    COUNT(CASE WHEN profit < 0 THEN 1 END) AS loss_orders,
    COUNT(*)                               AS total_orders,
    ROUND(COUNT(CASE WHEN profit < 0 THEN 1 END) / COUNT(*) * 100, 2) AS pct_loss_orders
FROM orders;

-- B5. Average days between orders per customer (repeat buyers)
WITH order_dates AS (
    SELECT
        customer_id,
        customer_name,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order
    FROM (SELECT DISTINCT customer_id, customer_name, order_date, order_id FROM orders) t
)
SELECT
    customer_name,
    ROUND(AVG(DATEDIFF(order_date, prev_order)), 0) AS avg_days_between_orders,
    COUNT(*) AS total_orders
FROM order_dates
WHERE prev_order IS NOT NULL
GROUP BY customer_id, customer_name
HAVING total_orders >= 3
ORDER BY avg_days_between_orders
LIMIT 15;
 
-- ============================================================
--  END OF PROJECT
-- ============================================================
