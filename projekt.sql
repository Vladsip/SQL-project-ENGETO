--Hlavni 1
 
SELECT *
FROM czechia_payroll cp 
WHERE industry_branch_code is null

SELECT *
FROM czechia_payroll_calculation cpc

SELECT *
FROM czechia_payroll_industry_branch cpib 

SELECT *
FROM czechia_payroll_unit cpu 

SELECT *
FROM czechia_payroll_value_type cpvt 

SELECT *
FROM czechia_price cp 

SELECT *
FROM czechia_price_category cpc 

--Ciselniky

SELECT *
FROM czechia_region cr 

SELECT *
FROM czechia_district cd 

--Dodatecne tabulky

SELECT *
FROM countries c
WHERE country = 'Czech Republic'

SELECT *
FROM economies e 
WHERE country = 'Czech Republic'


DROP TABLE IF EXISTS t_vladimir_sip_project_sql_primary_final 

--1. Vytvoreni CTE prumerne_rocni_mzdy 
CREATE TABLE IF NOT EXISTS t_vladimir_sip_project_SQL_primary_final AS
WITH wages_by_industry AS (
  SELECT
    cp.payroll_year AS year,
    ib.name AS industry_name,  
    AVG(cp.value) AS avg_wage_czk
  FROM czechia_payroll cp
  JOIN czechia_payroll_value_type vt ON cp.value_type_code = vt.code
  JOIN czechia_payroll_calculation cpc ON cp.calculation_code = cpc.code
  LEFT JOIN czechia_payroll_industry_branch ib ON cp.industry_branch_code = ib.code
  WHERE cp.value_type_code = 5958       
    AND cp.calculation_code = 200       
    AND cp.industry_branch_code IS NOT NULL
    AND cp.value IS NOT NULL
  GROUP BY cp.payroll_year, ib.name
), --2. Vytvoreni CTE prumerne_rocni_ceny
prices AS (
  SELECT
    EXTRACT(YEAR FROM p.date_from) AS year,
    c.code AS category_code,
    c.name AS product_name,  
    ROUND(AVG(p.value)::numeric, 1) AS avg_price_czk
  FROM czechia_price p
  JOIN czechia_price_category c ON p.category_code = c.code
  WHERE p.value IS NOT NULL
  GROUP BY EXTRACT(YEAR FROM p.date_from), c.code, c.name
), --3. Sjednoceni zkoumaneho obdobi (musi existovat jak mzdy, tak ceny)
common_years AS (
  SELECT DISTINCT pc.year
  FROM prices pc
  JOIN wages_by_industry wi ON pc.year = wi.year
) -- Finalni vyber
SELECT
  pc.year,
  pc.product_name,
  pc.avg_price_czk,
  wi.avg_wage_czk,
  wi.industry_name
FROM prices pc
JOIN wages_by_industry wi ON pc.year = wi.year
JOIN common_years cy ON pc.year = cy.year

SELECT *
FROM t_vladimir_sip_project_SQL_primary_final 



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

LAG(expression, offset, default_value) OVER (
  PARTITION BY partition_column
  ORDER BY order_column
)

    expression: The column or value you want to look back on.
    offset: How many rows behind to look. Defaults to 1 if omitted.
    default_value: What to return if no previous row exists (optional).
    PARTITION BY: (Optional) Splits data into groups, like by customer or region.
    ORDER BY: Required to define the row order.
    
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
    WHEN avg_wage_czk >  prev_wage THEN 'Increase'
    WHEN avg_wage_czk <  prev_wage THEN 'Decrease'
    ELSE 'No change'
  END AS change_label
FROM yoy
WHERE prev_wage IS NOT NULL
ORDER BY industry_name, year;

-- Odpoved na otazku 1. 
SELECT *
FROM v_yoy_wage_change 
WHERE change_label = 'Decrease'

/*
 * 🧠 Otázka 1:

Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?



Na základě analýzy meziroční změny průměrných mezd podle jednotlivých odvětví je zřejmé, že:

- Mzdy ve všech odvětvích nerostou neustále. V některých sektorech došlo v určitých letech k poklesu.

Z dostupných dat vyplývá, že během sledovaného období (zejména mezi lety 2009–2013) došlo u většiny odvětví alespoň v jednom roce k meziročnímu poklesu průměrné mzdy.
Tento vývoj naznačuje, že i přes celkový dlouhodobý trend růstu mezd, mohou nastat krátkodobé výkyvy – například v období ekonomické recese.

Příklady poklesů:

Peněžnictví a pojišťovnictví: −8,83 % (2013)

Výroba a rozvod elektřiny, plynu, tepla: −4,44 % (2013)

Stavebnictví: −2,06 % (2013)
*/

--2.Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

/*
- potřebuju najít nejstarší a nejnovější rok,
- potřebuju data o mzdách a cenách pro mléko a chléb,
- a spočítat: mzda / cena produktu.
*/
CREATE OR REPLACE VIEW quantity_affordable AS 
WITH first_and_last_year AS (
  SELECT MIN(year) AS first_year, MAX(year) AS last_year
  FROM t_vladimir_sip_project_sql_primary_final tvspspf 
),
filtered_data AS (
  SELECT *
  FROM t_vladimir_sip_project_SQL_primary_final
  WHERE product_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
)
SELECT
  f.product_name,
  f.year,
  ROUND(AVG(f.avg_wage_czk), 2) AS avg_wage_czk,
  ROUND(AVG(f.avg_price_czk), 2) AS avg_price_czk,
  ROUND(AVG(f.avg_wage_czk) / AVG(f.avg_price_czk), 0) AS quantity_affordable
FROM filtered_data f
JOIN first_and_last_year y ON f.year = y.first_year OR f.year = y.last_year
GROUP BY f.product_name, f.year;

SELECT *
FROM quantity_affordable 

/*
Na základě průměrných mezd a cen produktů ve společných letech bylo spočítáno, kolik jednotek mléka a chleba bylo možné si koupit 
za jednu měsíční mzdu:

Shrnutí:
Kupní síla se mírně zlepšila u obou produktů mezi roky 2006 a 2018.

I přes růst cen produktů vzrostly mzdy natolik, že si lidé mohou dovolit více litrů mléka a více kilogramů chleba než dříve.
*/

--3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 

-- 1. Průměrné ceny produktů za každý rok
CREATE OR REPLACE VIEW avg_yoy_price_pct AS 
WITH avg_prices AS (
  SELECT
    product_name,
    year,
    ROUND(AVG(avg_price_czk), 2) AS avg_price_czk
  FROM t_vladimir_sip_project_sql_primary_final
  GROUP BY product_name, year
),
-- 2. Výpočet meziroční změny pomocí LAG()
price_yoy_change AS (
  SELECT
    product_name,
    year,
    avg_price_czk,
    LAG(avg_price_czk) OVER (PARTITION BY product_name ORDER BY year) AS prev_price
  FROM avg_prices
),
-- 3. Výpočet procentuální změny
price_with_pct_change AS (
  SELECT
    product_name,
    year,
    avg_price_czk,
    prev_price,
    ROUND(
      CASE 
        WHEN prev_price = 0 THEN NULL
        ELSE ((avg_price_czk - prev_price) / prev_price) * 100
      END
    , 2) AS yoy_price_pct
  FROM price_yoy_change
  WHERE prev_price IS NOT NULL
)
-- 4. Výpočet průměrného meziročního růstu za produkt
SELECT
  product_name,
  ROUND(AVG(yoy_price_pct), 2) AS avg_yoy_price_pct
FROM price_with_pct_change
GROUP BY product_name
ORDER BY avg_yoy_price_pct ASC
/*
Na základě výpočtu průměrného meziročního růstu cen jednotlivých potravin za dostupné roky (2006–2018) 
lze určit, které potraviny zdražují nejpomaleji.
Nejpomaleji zdražující potravinou byl „Cukr krystalový“, jehož cena meziročně dokonce mírně klesala o −1,88 %.
Další potraviny s velmi nízkým růstem cen byly například rajská jablka a banány. 
Pokles cen cukru mezi lety 2006 a 2018 je ekonomicky vysvětlitelný:

-Zrušení cukerných kvót v EU (2017) vedlo k růstu produkce a tlaku na pokles cen.

-Nadprodukce na světovém trhu (např. Brazílie, Indie) snižovala ceny surového cukru globálně.

-Dovoz levnějšího cukru po vstupu ČR do EU zvýšil konkurenci a srazil ceny.
*/



--4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
/*
Meziroční procentuální změnu cen (YoY pro avg_price_czk)

Meziroční procentuální změnu mezd (YoY pro avg_wage_czk)

A porovnání těchto dvou změn
*/

SELECT *
FROM t_vladimir_sip_project_SQL_primary_final

/*
 Pouziti LAG Funkce

LAG(expression, offset, default_value) OVER (
  PARTITION BY partition_column
  ORDER BY order_column
)

    expression: The column or value you want to look back on.
    offset: How many rows behind to look. Defaults to 1 if omitted.
    default_value: What to return if no previous row exists (optional).
    PARTITION BY: (Optional) Splits data into groups, like by customer or region.
    ORDER BY: Required to define the row order.
*/

--LAG(avg_price_yearly) OVER (PARTITION BY product_name ORDER BY year) AS prev_year_price
--1. Mezirocni zmena cen produktu
 
WITH average_prices AS (
    SELECT
        product_name, 
        year,
        ROUND(AVG(avg_price_czk), 2) AS avg_price_yearly
    FROM t_vladimir_sip_project_sql_primary_final 
    GROUP BY product_name, YEAR
),
prices_with_lag AS (
    SELECT 
        product_name,
        year,
        avg_price_yearly,
        LAG(avg_price_yearly) OVER (PARTITION BY product_name ORDER BY year) AS prev_year_price
    FROM average_prices     
),
price_yoy_change AS (
    SELECT
        product_name,
        year,
        avg_price_yearly,
        prev_year_price,
        ROUND(
            CASE 
                WHEN prev_year_price IS NULL OR prev_year_price = 0 THEN NULL
                ELSE ((avg_price_yearly - prev_year_price) / prev_year_price) * 100
            END
        , 2) AS yoy_price_pct
    FROM prices_with_lag
),
--2.Mezirocni zmena mezd 
average_wages AS (
    SELECT
        industry_name, 
        year,
        ROUND(AVG(avg_wage_czk), 2) AS avg_wage_yearly
    FROM t_vladimir_sip_project_sql_primary_final 
    GROUP BY industry_name, year
),
wages_with_lag AS (
    SELECT 
        industry_name,
        year,
        avg_wage_yearly,
        LAG(avg_wage_yearly) OVER (PARTITION BY industry_name ORDER BY year) AS prev_year_wage
    FROM average_wages     
),
wage_yoy_change AS (
    SELECT
        industry_name,
        year,
        avg_wage_yearly,
        prev_year_wage,
        ROUND(
            CASE 
                WHEN prev_year_wage IS NULL OR prev_year_wage = 0 THEN NULL
                ELSE ((avg_wage_yearly - prev_year_wage) / prev_year_wage) * 100
            END
        , 2) AS yoy_wage_pct
    FROM wages_with_lag
),
--3.Spojeni a porovnani
compared_changes AS ( 
    SELECT 
        w.industry_name,
        p.product_name,
        p.YEAR,
        p.yoy_price_pct,
        w.yoy_wage_pct,
        ROUND(p.yoy_price_pct - w.yoy_wage_pct, 2) AS price_vs_wage_diff
    FROM price_yoy_change p
    JOIN wage_yoy_change w ON p.YEAR = w.year    
)    
SELECT *
FROM compared_changes 
WHERE price_vs_wage_diff >10
ORDER BY year
;

-- 1. Ceny vybraného produktu
WITH price_change AS (
  SELECT
    year,
    ROUND(AVG(avg_price_czk), 2) AS avg_price_czk,
    LAG(ROUND(AVG(avg_price_czk), 2)) OVER (ORDER BY year) AS prev_price
  FROM t_vladimir_sip_project_sql_primary_final
  WHERE product_name = 'Papriky'
  GROUP BY year
),
price_change_pct AS (
  SELECT
    year,
    avg_price_czk,
    prev_price,
    ROUND(
      CASE 
        WHEN prev_price = 0 THEN NULL
        ELSE ((avg_price_czk - prev_price) / prev_price) * 100
      END, 2
    ) AS yoy_price_pct
  FROM price_change
),
-- 2. Celková průměrná mzda (napříč všemi odvětvími)
avg_wage_change AS (
  SELECT
    year,
    ROUND(AVG(avg_wage_czk), 2) AS avg_wage_czk,
    LAG(ROUND(AVG(avg_wage_czk), 2)) OVER (ORDER BY year) AS prev_wage
  FROM t_vladimir_sip_project_sql_primary_final
  GROUP BY year
),
avg_wage_change_pct AS (
  SELECT
    year,
    avg_wage_czk,
    prev_wage,
    ROUND(
      CASE 
        WHEN prev_wage = 0 THEN NULL
        ELSE ((avg_wage_czk - prev_wage) / prev_wage) * 100
      END, 2
    ) AS yoy_wage_pct
  FROM avg_wage_change
)
-- 3. Výstup: spojení podle roku
SELECT
  p.year,
  p.yoy_price_pct,
  w.yoy_wage_pct,
  ROUND(p.yoy_price_pct - w.yoy_wage_pct, 2) AS price_vs_wage_diff
FROM price_change_pct p
JOIN avg_wage_change_pct w ON p.year = w.year
ORDER BY p.year;



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

--Výsledek ukazuje meziroční procentuální změnu mediánové ceny potravin vs. mediánové mzdy pro každý rok a jejich rozdíl.
--Ano, v roce 2012 byl meziroční nárůst cen potravin výrazně vyšší než růst mezd.

SELECT *
FROM t_vladimir_sip_project_sql_primary_final

/*
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či 
mzdách ve stejném nebo následujícím roce výraznějším růstem?
*/

/*Získat pro Českou republiku:
-HDP na obyvatele (gdp_per_capita)
-Rok
*/

--Tvorba sekundarni tabulky
SELECT *
FROM countries c
WHERE country = 'Czech Republic'

SELECT *
FROM economies e 
WHERE country = 'Czech Republic'

DROP TABLE IF EXISTS t_vladimir_sip_project_SQL_secondary_final 


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

-- 4.vypocet gdp_growth_pct – meziroční růst HDP v %, wage_growth_pct – meziroční růst mezd v %, price_growth_pct - meziroční růst cen potravin v %
CREATE OR REPLACE VIEW v_gdp_price_wage AS 
WITH gdp_cte AS (
    SELECT 
        country,
        YEAR,
        gdp,
        LAG(gdp) OVER (ORDER BY year) AS prev_gdp
    FROM t_vladimir_sip_project_SQL_secondary_final tf
),
median_prices AS (
    SELECT year,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_price_czk) AS median_price
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY year
),
median_wages AS (
    SELECT year,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_wage_czk) AS median_wage
    FROM t_vladimir_sip_project_sql_primary_final
    GROUP BY YEAR
),
combined AS (
    SELECT 
        g.country,
        g.YEAR,
        g.gdp,
        g.prev_gdp,
        mp.median_price,
        LAG (mp.median_price) OVER (ORDER BY g.year) AS prev_price,
        mw.median_wage,
        LAG (mw.median_wage) OVER (ORDER BY g.year) AS prev_wage
    FROM gdp_cte g
LEFT JOIN median_prices mp ON g.YEAR = mp.YEAR
LEFT JOIN median_wages mw ON g.YEAR = mw.year
)
SELECT 
        country,
        YEAR,
        gdp,
        ROUND(((gdp-prev_gdp)/prev_gdp)::NUMERIC *100, 2) AS yoy_gdp_pct,
        ROUND(((median_price-prev_price)/prev_price)::NUMERIC *100, 2) AS yoy_price_pct, 
        ROUND(((median_wage-prev_wage)/prev_wage)::NUMERIC *100, 2) AS yoy_wage_pct
FROM combined
ORDER BY YEAR; 


/*5. Má výška HDP vliv na změny ve mzdách a cenách potravin?

Pro ověření této hypotézy byl analyzován meziroční procentuální růst HDP, mezd (medián napříč odvětvími) a cen potravin (medián napříč produkty) v letech 2007–2018.

Závěry:

Růst HDP nemá konzistentní vliv na změny v cenách potravin ani mzdách.

Např. v roce 2012 došlo k prudkému růstu cen potravin (+17,48 %), ale zároveň:

HDP se téměř nezměnil (-0,79 %)

Mzdy rostly jen mírně (+2,42 %)

Naopak v roce 2017 vzrostly HDP i mzdy poměrně výrazně, zatímco ceny potravin téměř stagnovaly.

Interpretace:

Růst HDP nemusí automaticky znamenat odpovídající růst mezd nebo cen potravin ve stejném roce. Mezi těmito veličinami nebyla prokázána jednoznačná korelace, a jejich vývoj je ovlivněn i dalšími faktory
*/
