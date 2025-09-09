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
