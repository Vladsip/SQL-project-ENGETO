-- 5.vypocet gdp_growth_pct – meziroční růst HDP v %, wage_growth_pct – meziroční růst mezd v %, price_growth_pct - meziroční růst cen potravin v %
CREATE OR REPLACE VIEW v_gdp_price_wage AS 
WITH gdp_cte AS (
    SELECT 
        country,
        YEAR,
        gdp,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp
    FROM t_vladimir_sip_project_SQL_secondary_final tf
),
avg_prices AS (
    SELECT year,
           ROUND(AVG(avg_price_czk), 2) AS avg_price
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY year
),
avg_wages AS (
    SELECT year,
           ROUND(AVG(avg_wage_czk), 2) AS avg_wage
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY YEAR
),
combined AS (
    SELECT 
        g.country,
        g.YEAR,
        g.gdp,
        g.prev_gdp,
        ap.avg_price,
        LAG(ap.avg_price) OVER (ORDER BY g.year) AS prev_price,
        aw.avg_wage,
        LAG(aw.avg_wage) OVER (ORDER BY g.year) AS prev_wage
    FROM gdp_cte g
LEFT JOIN avg_prices ap ON g.YEAR = ap.YEAR
LEFT JOIN avg_wages aw ON g.YEAR = aw.year
)
SELECT 
    country,
    YEAR,
    gdp,
    ROUND(((gdp - prev_gdp) / prev_gdp * 100)::NUMERIC, 2) AS yoy_gdp_pct,
    ROUND(((avg_price - prev_price) / prev_price * 100)::NUMERIC, 2) AS yoy_price_pct,
    ROUND(((avg_wage - prev_wage) / prev_wage * 100)::NUMERIC, 2) AS yoy_wage_pct
FROM combined
ORDER BY YEAR;

SELECT *
FROM v_gdp_price_wage vgpw 









w