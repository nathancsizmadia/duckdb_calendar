WITH easter_calc AS (
    SELECT 
        year_key,
        (year_key % 19) AS a,
        (year_key // 100) AS b,
        (year_key % 100) AS c,
        (b // 4) AS d,
        (b % 4) AS e,
        ((b + 8) // 25) AS f,
        ((b - f + 1) // 3) AS g,
        ((19 * a + b - d - g + 15) % 30) AS h,
        (c // 4) AS i,
        (c % 4) AS k,
        ((32 + 2 * e + 2 * i - h - k) % 7) AS l,
        ((a + 11 * h + 22 * l) // 451) AS m,
        ((h + l - 7 * m + 114) // 31) AS month_val,
        ((h + l - 7 * m + 114) % 31) + 1 AS day_val
    FROM dim_calendar
    WHERE year_key
      AND day_of_month = 1 -- limit to one day for the year
      AND month_of_year = 1 -- limit to one day for the year
),

easter_date AS (
    SELECT 
        year_key,
        make_date(year_key, month_val, day_val) AS easter_sunday
    FROM easter_calc
),

easter_dates AS (
    SELECT 
        year_key,
        unnest([
            easter_sunday - INTERVAL '2 days',
            easter_sunday,
            easter_sunday + INTERVAL '1 day'
        ])::DATE AS easter_dates
    FROM easter_date
)


SELECT 
  c.date_key,
  CASE 
    WHEN c.month_of_year = 1 AND c.day_of_month = 1 THEN 'New Year''s Day'
    WHEN c.month_of_year = 1 AND c.day_of_month = 26 THEN 'Australia Day'
    WHEN c.month_of_year = 4 AND c.day_of_month = 25 THEN 'Anzac Day'
    WHEN c.month_of_year = 12 AND c.day_of_month = 25 THEN 'Christmas Day'
    WHEN c.month_of_year = 12 AND c.day_of_month = 26 THEN 'Boxing Day'
    WHEN e.easter_dates IS NOT NULL AND c.day_name_short = 'Fri' THEN 'Good Friday'
    WHEN e.easter_dates IS NOT NULL AND c.day_name_short = 'Sun' THEN 'Easter Sunday'
    WHEN e.easter_dates IS NOT NULL AND c.day_name_short = 'Mon' THEN 'Easter Monday'
  END AS public_holiday_nm,
FROM dim_calendar c
LEFT JOIN easter_dates e
ON c.date_key = e.easter_dates
WHERE c.year_key = 2026
ORDER BY 
  c.date_key