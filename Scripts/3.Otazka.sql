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
