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

WITH prices_with_lag AS (
  SELECT
    product_name,
    year,
    ROUND(AVG(avg_price_czk), 2) AS avg_price,
    LAG(ROUND(AVG(avg_price_czk), 2)) OVER (PARTITION BY product_name ORDER BY year) AS prev_price
  FROM t_vladimir_sip_project_sql_primary_final
  GROUP BY product_name, year
)
SELECT
  product_name,
  year,
  avg_price,
  prev_price,
  ROUND(((avg_price - prev_price) / prev_price) * 100, 2) AS yoy_price_pct
FROM prices_with_lag
WHERE year = 2012 AND prev_price IS NOT NULL
ORDER BY yoy_price_pct DESC




    YEAR,
    avg(yoy_price_pct) AS avg_yoy_price_pct
FROM yoy_price_pct 
GROUP BY year


/*
 * Proč vejce v roce 2012 zdražila o více než 50 %?

Hlavním důvodem byl zásadní regulační zásah EU:

✅ 1. Nová legislativa EU – zákaz klecových chovů

Od 1. 1. 2012 vstoupila v platnost směrnice EU, která zakazovala původní (neobohacené) klece pro nosnice.

Všechny chovy musely vejce produkovat v tzv. obohacených klecích s větším prostorem, hřady, podestýlkou atd.

Zhruba třetina evropských chovatelů však nebyla připravena → pokles nabídky vajec.

✅ 2. Nedostatek vajec na evropském trhu

Kvůli poklesu produkce v EU (zejména ve východní Evropě) nastal vážný nedostatek vajec.

Některé země přestaly vejce vyvážet, jiné je musely dovážet za vyšší ceny.

Česká republika nebyla soběstačná, musela vejce draze dovážet, což vyhnalo ceny vzhůru.

✅ 3. Panikářský nákup vajec (mediální vlna)

Média v březnu 2012 často psala o „krizi vajec“.

Spotřebitelé začali vykupovat vejce ve velkém, což dále zvyšovalo tlak na ceny.
*/
 */
w