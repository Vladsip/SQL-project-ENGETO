--3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 

CREATE OR REPLACE VIEW avg_yoy_price_pct AS 
WITH avg_prices AS (
  SELECT
    product_name,
    year,
    ROUND(AVG(avg_price_czk), 2) AS avg_price_czk
  FROM t_vladimir_sip_project_sql_primary_final
  GROUP BY product_name, year
),
price_yoy_change AS (
  SELECT
    product_name,
    year,
    avg_price_czk,
    LAG(avg_price_czk) OVER (PARTITION BY product_name ORDER BY year) AS prev_price
  FROM avg_prices
),
price_with_pct_change AS (
  SELECT
    product_name,
    year,
    avg_price_czk,
    prev_price,
    ROUND(
  ((avg_price_czk - prev_price) / NULLIF(prev_price, 0)) * 100,
  2) AS yoy_price_pct
  FROM price_yoy_change
  WHERE prev_price IS NOT NULL
)
SELECT
  product_name, year, avg_price_czk, prev_price, yoy_price_pct
FROM price_with_pct_change;

SELECT * 
FROM avg_yoy_price_pct aypp 


--3. Výpočet průměrného meziročního růstu za produkt

SELECT
  product_name,
  ROUND(AVG(yoy_price_pct), 2) AS avg_yoy_price_pct
FROM avg_yoy_price_pct
GROUP BY product_name
ORDER BY avg_yoy_price_pct ASC;

/