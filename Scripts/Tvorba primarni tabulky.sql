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


CREATE TABLE IF NOT EXISTS t_vladimir_sip_project_SQL_primary_final AS
--1. Vytvoreni CTE prumerne_rocni_mzdy 
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