WITH easter_calc AS (
    SELECT 
        year_val,
        (year_val % 19) AS a,
        (year_val // 100) AS b,
        (year_val % 100) AS c,
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
        ((h + l - 7 * m + 114) % 31) + 1 AS day_val,
        make_date(year_val, month_val, day_val) AS easter_sunday
    FROM (SELECT range AS year_val FROM range(1900, 10000)) -- Set your year range here
)
SELECT 
    year_val,
    easter_sunday,
    easter_sunday - INTERVAL '2 days' AS good_friday,
    easter_sunday + INTERVAL '1 day' AS easter_monday
FROM easter_calc;