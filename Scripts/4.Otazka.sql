--4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?


CREATE OR REPLACE VIEW price_vs_wage_diff AS 
WITH avg_prices AS (
    SELECT 
        year,
        AVG(avg_price_czk) AS avg_price
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY year
),
avg_wages AS (
    SELECT 
        year,
        AVG(avg_wage_czk) AS avg_wage
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY year
),
combined AS (
    SELECT 
        p.year,
        p.avg_price,
        w.avg_wage,
        LAG(p.avg_price) OVER (ORDER BY p.year) AS prev_price,
        LAG(w.avg_wage) OVER (ORDER BY w.year) AS prev_wage
    FROM avg_prices p
    JOIN avg_wages w ON p.year = w.year
),
change_analysis AS (
    SELECT
        year,
        ROUND(((avg_price - prev_price) / prev_price * 100)::NUMERIC, 2) AS yoy_price_pct,
        ROUND(((avg_wage - prev_wage) / prev_wage * 100)::NUMERIC, 2) AS yoy_wage_pct,
        ROUND((((avg_price - prev_price) / prev_price * 100) - ((avg_wage - prev_wage) / prev_wage * 100))::NUMERIC, 2) AS price_vs_wage_diff
    FROM combined
    WHERE prev_price IS NOT NULL AND prev_wage IS NOT NULL
      AND prev_price <> 0 AND prev_wage <> 0
)
SELECT *
FROM change_analysis;

SELECT *
 FROM price_vs_wage_diff pvwd 



WITH prices_with_lag AS (
SELECT 
    YEAR,
    product_name ,
    max(avg_price_czk) AS avg_price,
    LAG (max(avg_price_czk)) OVER (PARTITION BY product_name ORDER BY year) AS prev_price
FROM t_vladimir_sip_project_sql_primary_final tvspspf
GROUP BY YEAR,product_name 
ORDER BY YEAR,product_name 
)
SELECT 
    YEAR,
    product_name,
    avg_price ,
    prev_price,
    ROUND(((avg_price-prev_price)/prev_price) *100, 2) AS yoy_price_pct
FROM prices_with_lag
WHERE prev_price IS NOT NULL AND YEAR = 2009
ORDER BY yoy_price_pct 

