# Analýza vývoje mezd, cen potravin a HDP v ČR (2006–2018)

Tento projekt se zaměřuje na datovou analýzu vývoje průměrných mezd, cen vybraných potravin a hrubého domácího produktu (HDP) v České republice mezi lety 2006 a 2018. Cílem bylo zodpovědět několik konkrétních otázek pomocí nástroje SQL a vyhodnotit ekonomické souvislosti:

*1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?  
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?  
3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?   
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?  
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?*

Součástí analýzy bylo vytváření agregačních přehledů, výpočty meziročních změn, použití funkcí jako LAG, PERCENTILE_CONT pro výpočet mediánu, práce s CTE a pohledy (views). 

## Použité nástroje
Pro analýzu cen potravin a HDP jsem využil následující nástroje:
  - **SQL:**  Základní nástroj, pomocí kterého jsem se dotazoval do databáze a získával klíčové informace.
  - **PostgreSQL:** Systém pro správu databází.
  - **DBeaver:** Nástroj pro práci s databází. 
  - **Visual Studio Code:** Použitý především pro správu repozitáře, psaní souboru README.md a základní úpravy projektu.
  - **Git & GitHub:** Sdílení mých skriptů a analýz.

# Analýza
### 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?  

Abych mohl meziročně analyzovat vývoj mezd, nejprve jsem vytvořil pohled v_wages_by_industry nad primární tabulkou t_vladimir_sip_project_SQL_primary_final. 
```
CREATE OR REPLACE VIEW v_wages_by_industry AS
SELECT
  year,
  industry_name,
  MAX(avg_wage_czk) AS avg_wage_czk
FROM t_vladimir_sip_project_SQL_primary_final
GROUP BY year, industry_name;
```
Tento pohled obsahuje agregované průměrné mzdy podle roku a odvětví. Dále jsem vytvořil druhý pohled v_yoy_wage_change, ve kterém pomocí funkce LAG počítám meziroční změnu mezd (v absolutních hodnotách i procentech).

```
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
```
A na závěr jsem vyfiltroval pouze hodnoty 'Decreased' ze sloupce change_label.
```
SELECT *
FROM v_yoy_wage_change 
WHERE change_label = 'Decreased'
```
Výsledky ukazují, že:

-  Ve většině odvětví mzdy rostou.

-  Nicméně se vyskytují případy meziročního poklesu mezd, zejména v roce 2013 v sektorech peněžnictví a pojištěnství, energetika či těžba. 

![pokles_mezd_heatmap](Obrazky/pokles_mezd_heatmap.png)
*Heatmap znázorňující meziroční pokles mezd v jednotlivých odvětvích (v %); vygenerováno pomocí ChatGPT s výsledků mého SQL dotazu.*




