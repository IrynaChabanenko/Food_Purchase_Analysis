--Top categories in which I bought the most units of products
WITH ranked_categories AS (
    SELECT 
        c.category_name, 
        ROW_NUMBER() OVER (
            ORDER BY SUM(
                CASE 
                    WHEN p.measurement = 'kg' THEN 1
                    ELSE p.quantity
                END
            ) DESC
        ) AS row_nmb,
        SUM(
            CASE 
                WHEN p.measurement = 'kg' THEN 1
                ELSE p.quantity
            END
        ) AS quantity
    FROM purchases p
    LEFT JOIN products t ON t.product_id = p.product_id
    LEFT JOIN categories c ON c.category_id = t.category_id
    WHERE c.category_name <> 'Non-food products'
    GROUP BY c.category_name
)
SELECT 
    CASE 
        WHEN row_nmb <= 3 THEN category_name 
        ELSE 'Other'
    END AS category,
    SUM(quantity) AS purchase_quantity,
    ROUND(SUM(quantity)::NUMERIC * 100 / SUM(SUM(quantity)::NUMERIC) OVER (), 0) AS percentage_of_total
FROM ranked_categories
GROUP BY category
ORDER BY purchase_quantity DESC;


--Which categories take the most money?
SELECT 
    c.category_name,
    ROUND(SUM(CAST(p.quantity AS NUMERIC) * CAST(p.price_per_unit AS NUMERIC)), 0) AS total_cost
FROM purchases p
LEFT JOIN products t USING (product_id)
LEFT JOIN categories c USING (category_id)
WHERE c.category_name <> 'Non-food products'
GROUP BY c.category_name
ORDER BY total_cost DESC;

--- What % of impulse purchases are in all purchases?
SELECT  
    (
        (SELECT count(*) 
         FROM purchases p 
         WHERE p.purchase_planning = 'unplanned') * 100 / COUNT(*)
    ) AS percentage_unplanned
FROM purchases p;

--What day of the week do I visit stores more often
SELECT 
    to_char(transaction_date, 'day') AS week_day, 
    count(receipt_number) AS nmb_visit_store
FROM receipts r
GROUP BY week_day
ORDER BY nmb_visit_store;

--The day of the week I have the largest average receipt
SELECT 
    to_char(r.transaction_date, 'day') AS week_day,
    ROUND(CAST(SUM(p.quantity * p.price_per_unit) / COUNT(DISTINCT r.receipt_number) AS numeric), 0) AS Expenses
FROM receipts r
RIGHT JOIN purchases p USING (receipt_number)
GROUP BY week_day
ORDER BY expenses DESC;

--The impact of a discount on impulse purchases
SELECT 
    'Percentage of discounted products among unplanned purchases' AS INDICATOR,
    ROUND((
        (COUNT(*) / (
            SELECT COUNT(*) AS plan_purchase
            FROM purchases p 
            WHERE purchase_planning = 'unplanned'
        )::NUMERIC) * 100), 2) AS Percentage
FROM purchases p 
WHERE discount = TRUE AND purchase_planning = 'unplanned'

UNION ALL

SELECT 
    'Percentage of discounted products among planned purchases' AS INDICATOR,
    ROUND((
        (COUNT(*) / (
            SELECT COUNT(*) AS plan_purchase
            FROM purchases p 
            WHERE purchase_planning = 'planned'
        )::NUMERIC) * 100), 2) AS Percentage
FROM purchases p 
WHERE discount = TRUE AND purchase_planning = 'planned';
