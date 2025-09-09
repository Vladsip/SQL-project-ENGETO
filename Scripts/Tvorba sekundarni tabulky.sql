--1.Roky, které jsou použity v primarni tabulce
CREATE TABLE IF NOT EXISTS t_vladimir_sip_project_SQL_secondary_final AS
WITH common_years AS (
    SELECT 
        DISTINCT YEAR
    FROM t_vladimir_sip_project_SQL_primary_final 
), --2.Filtrování údajů o ČR z tabulky economies
economy_cz AS (
    SELECT 
        country,
        YEAR,
        gdp
    FROM economies  
    WHERE country = 'Czech Republic'
)
SELECT --3.finalni vyber s pripojenou pomocnou tabulkou pouze s roky, ktere mame i v primarni tabulce
    country,
    e.YEAR,
    e.gdp
FROM economy_cz e
JOIN common_years cm ON e.YEAR = cm.year

SELECT * 
FROM t_vladimir_sip_project_SQL_secondary_final 
