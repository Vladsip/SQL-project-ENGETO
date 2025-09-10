--1.Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

--Vytvoreni view pro znazorneni mezd v jednotlivych odvetvi a letech 

CREATE OR REPLACE VIEW v_wages_by_industry AS
SELECT
  year,
  industry_name,
  MAX(avg_wage_czk) AS avg_wage_czk
FROM t_vladimir_sip_project_SQL_primary_final
GROUP BY year, industry_name;

SELECT *
FROM v_wages_by_industry 

--
/*
 Pouziti LAG Funkce
   
    LAG(<výraz> [, <offset> [, <default>]])
OVER (PARTITION BY <skupina> ORDER BY <pořadí>)

    <výraz> – sloupec/počítaný výraz, jehož minulou hodnotu chceš.

    <offset> – o kolik řádků zpět (default 1).

    <default> – co vrátit, když minulý řádek neexistuje (default NULL).

    PARTITION BY – volitelné, rozdělí data do skupin (např. industry_name).

    ORDER BY – povinné, určuje čas/pořadí.
    
    Funkce NULLIF(a, b) :

Porovná hodnoty a a b.

Pokud jsou stejné, vrátí NULL.

Pokud jsou různé, vrátí hodnotu a.

Když je prev_wage = 0, dostaneme NULL, takže dělení x / NULL vrátí NULL místo chyby.
*/

CREATE OR REPLACE VIEW v_yoy_wage_change AS
WITH yoy AS (
  SELECT
    industry_name,
    year,
    avg_wage_czk,
    LAG(avg_wage_czk) OVER (PARTITION BY industry_name ORDER BY year) AS prev_wage
  FROM v_wages_by_industry
)
SELECT
  industry_name,
  year,
  avg_wage_czk,
  ROUND(avg_wage_czk - prev_wage, 2) AS yoy_wage_abs,
  ROUND( (avg_wage_czk - prev_wage) / NULLIF(prev_wage,0) * 100, 2 ) AS yoy_wage_pct,
  CASE
    WHEN prev_wage IS NULL THEN 'N/A'
    WHEN avg_wage_czk >  prev_wage THEN 'Increased'
    WHEN avg_wage_czk <  prev_wage THEN 'Decreased'
    ELSE 'No change'
  END AS change_label
FROM yoy
WHERE prev_wage IS NOT NULL
ORDER BY industry_name, year;

SELECT *
FROM v_yoy_wage_change vywc 

-- Odpoved na otazku 1. 
SELECT *
FROM v_yoy_wage_change 
WHERE change_label = 'Decreased'

