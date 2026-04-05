DROP TABLE IF EXISTS dim_calendar;

CREATE TABLE dim_calendar AS
	
WITH generate_date AS (
   SELECT CAST(RANGE AS DATE) AS date_key 
   FROM RANGE(DATE '1900-01-01', DATE '9999-12-31', INTERVAL 1 DAY)
     )

SELECT 
  date_key,
  epoch(date_key) AS epoch_seconds,
  YEARWEEK(date_key) AS week_key,
  WEEKOFYEAR(date_key)::UINT8 AS week_of_year,
  WEEKOFYEAR(date_key + 2)::UINT8 AS week_of_year_sat,
  DAYOFWEEK(date_key)::UINT8 AS day_of_week,
  ISODOW(date_key)::UINT8 AS iso_day_of_week,
  DAYNAME(date_key) AS day_name,
  LEFT(DAYNAME(date_key),3) AS day_name_short,
  DATE_TRUNC('week', date_key) AS first_day_of_week,
  DATE_TRUNC('week', date_key) + 6 AS last_day_of_week,
  YEAR(date_key) || RIGHT('0' || MONTH(date_key), 2) AS month_key,
  DAYOFYEAR(date_key)::UINT16 AS day_of_year, 
  MONTH(date_key)::UINT8 AS month_of_year,
  DAYOFMONTH(date_key)::UINT8 AS day_of_month,
  CASE 
    WHEN day(date_key) IN (11, 12, 13) THEN 'th'
    WHEN day(date_key) % 10 = 1 THEN 'st'
    WHEN day(date_key) % 10 = 2 THEN 'nd'
    WHEN day(date_key) % 10 = 3 THEN 'rd'
    ELSE 'th' 
  END AS day_suffix,
  LEFT(MONTHNAME(date_key), 3) AS month_name_short,
  MONTHNAME(date_key) AS month_name,
  DATE_TRUNC('month', date_key) AS first_day_of_month,
  LAST_DAY(date_key) AS last_day_of_month,
  CAST(YEAR(date_key) || QUARTER(date_key) AS INT) AS quarter_key,
  QUARTER(date_key)::UINT8 AS quarter_of_year,
  (DATEDIFF('day', DATE_TRUNC('quarter', date_key::TIMESTAMP), date_key) + 1)::UINT8 AS day_of_quarter,
  ('Q' || QUARTER(date_key)) AS quarter_desc_short,
  ('Quarter ' || QUARTER(date_key)) AS quarter_desc,
  DATE_TRUNC('quarter', date_key) AS first_day_of_quarter,
  LAST_DAY(DATE_TRUNC('quarter', date_key) + INTERVAL 2 MONTH) as last_day_of_quarter,
  CAST(YEAR(date_key) AS INT) AS year_key,
  DATE_TRUNC('Year', date_key) AS first_day_of_year,
  (DATE_TRUNC('Year', date_key) - 1 + INTERVAL 1 YEAR)::DATE AS last_day_of_year,
  ROW_NUMBER() OVER (PARTITION BY YEAR(date_key), MONTH(date_key), DAYOFWEEK(date_key) ORDER BY date_key)::UINT8 AS ordinal_weekday_of_month,
  (CASE WHEN weekday(date_key) IN (0,6) THEN 1 ELSE 0 END)::UINT8 AS is_weekend
FROM generate_date;
