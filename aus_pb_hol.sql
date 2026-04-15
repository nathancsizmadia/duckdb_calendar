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
        ((h + l - 7 * m + 114) % 31) + 1 AS day_val,
        make_date(year_key, month_val, day_val) AS easter_sunday
    FROM dim_calendar
    WHERE year_key
      AND day_of_month = 1 -- limit to one day for the year
      AND month_of_year = 1 -- limit to one day for the year
),

easter_dates AS (
    SELECT 
        year_key,
        unnest([
            easter_sunday - INTERVAL '2 days',
            easter_sunday,
            easter_sunday + INTERVAL '1 day'
        ])::DATE AS easter_dates
    FROM easter_calc
),

aus_pb_hol AS (
    SELECT 
      c.*,
      CASE 
        WHEN c.month_of_year = 1 AND c.day_of_month = 1 THEN 'New Year''s Day'
        WHEN c.month_of_year = 1 AND c.day_of_month = 26 THEN 'Australia Day'
        WHEN e.easter_dates IS NOT NULL AND c.day_name_short = 'Fri' THEN 'Good Friday'
        WHEN e.easter_dates IS NOT NULL AND c.day_name_short = 'Sun' THEN 'Easter Sunday'
        WHEN e.easter_dates IS NOT NULL AND c.day_name_short = 'Mon' THEN 'Easter Monday'
        WHEN c.month_of_year = 4 AND c.day_of_month = 25 THEN 'Anzac Day'
        WHEN c.month_of_year = 12 AND c.day_of_month = 25 THEN 'Christmas Day'
        WHEN c.month_of_year = 12 AND c.day_of_month = 26 THEN 'Boxing Day'
      END AS public_holiday_nm,
    FROM dim_calendar c
    LEFT JOIN easter_dates e
    ON c.date_key = e.easter_dates
),

observed_logic AS (
    -- 2. Use Window Functions to check the weekend status
    SELECT 
        *,
        -- Peek at yesterday
        LAG(public_holiday_nm, 1) OVER (ORDER BY date_key) AS hol_yesterday,
        -- Peek at two days ago
        LAG(public_holiday_nm, 2) OVER (ORDER BY date_key) AS hol_2_days_ago
    FROM aus_pb_hol
),

clndr AS (
    SELECT 
        *,
        CASE 
            -- Standard Holiday
            WHEN public_holiday_nm IS NOT NULL THEN public_holiday_nm
    
            WHEN iso_day_of_week = 1 AND COALESCE(hol_yesterday, hol_2_days_ago) = 'Anzac Day' THEN NULL
            
            -- Special Christmas weekend shift (Specifically for Boxing Day when it follows a Sunday Xmas)
            WHEN iso_day_of_week = 1 AND hol_2_days_ago = 'Christmas Day' THEN 'Christmas Day (Observed)'
            WHEN iso_day_of_week = 2 AND hol_2_days_ago = 'Boxing Day' THEN 'Boxing Day (Observed)'
            WHEN iso_day_of_week = 2 AND hol_yesterday = 'Boxing Day' THEN 'Christmas Day (Observed)'
    
            WHEN iso_day_of_week = 1 AND COALESCE(hol_yesterday,hol_2_days_ago) IS NOT NULL
              THEN COALESCE(hol_yesterday,hol_2_days_ago) || ' (Observed)'
            
            ELSE NULL 
        END AS final_holiday_status
    FROM observed_logic
)

SELECT 
    * EXCLUDE(hol_yesterday, hol_2_days_ago, public_holiday_nm, final_holiday_status),
    CASE WHEN final_holiday_status IS NOT NULL THEN 1 ELSE 0 END AS is_public_holiday,
    final_holiday_status AS public_holiday_nm,
    CASE WHEN final_holiday_status IS NOT NULL THEN 'All' END AS public_holiday_state,
FROM clndr;