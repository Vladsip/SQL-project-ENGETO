--4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?


CREATE OR REPLACE VIEW price_vs_wage_diff AS 
WITH median_prices AS (
    SELECT year,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_price_czk) AS median_price
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY year
),
median_wages AS (
    SELECT year,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_wage_czk) AS median_wage
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY year
),
combined AS (
    SELECT 
        p.year,
        p.median_price,
        w.median_wage,
        LAG(p.median_price) OVER (ORDER BY p.year) AS prev_price,
        LAG(w.median_wage) OVER (ORDER BY w.year) AS prev_wage
    FROM median_prices p
    JOIN median_wages w ON p.year = w.year
),
change_analysis AS (
    SELECT
        year,
        ROUND(((median_price - prev_price) / prev_price * 100)::NUMERIC, 2) AS yoy_price_pct,
        ROUND(((median_wage - prev_wage) / prev_wage * 100)::NUMERIC, 2) AS yoy_wage_pct,
        ROUND((((median_price - prev_price) / prev_price * 100) - ((median_wage - prev_wage) / prev_wage * 100))::NUMERIC, 2) AS price_vs_wage_diff
    FROM combined
    WHERE prev_price IS NOT NULL AND prev_wage IS NOT NULL
      AND prev_price <> 0 AND prev_wage <> 0
)
SELECT *
FROM change_analysis

SELECT *
FROM price_vs_wage_diff pvwd 

--Výsledek ukazuje meziroční procentuální změnu mediánové ceny potravin vs. mediánové mzdy pro každý rok a jejich rozdíl.
--Ano, v roce 2012 byl meziroční nárůst cen potravin výrazně vyšší než růst mezd.

