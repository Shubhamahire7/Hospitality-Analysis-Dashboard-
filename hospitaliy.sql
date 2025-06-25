 
-- 1 total revene
-- total expected revenue 
SELECT sum(revenue_generated) FROM hospi.fact_bookings;
-- final revenue (some booking gets canceled)
SELECT sum(revenue_realized) FROM hospi.fact_bookings;

-- 2  Total Bookings
select count(booking_id)  from fact_bookings;

-- 3 Total Capacity
select sum(capacity) from fact_aggregated_bookings;

-- 4 Total Succesful Bookings
select sum(successful_bookings) from fact_aggregated_bookings;

-- 5 Occupancy %
SELECT 
    property_id,
    check_in_date,
    room_category,
    successful_bookings,
    capacity,
    CASE 
        WHEN capacity = 0 THEN 0  -- Avoid division by zero
        ELSE (successful_bookings * 100.0) / capacity
    END AS occupancy_percent
FROM fact_aggregated_bookings
ORDER BY occupancy_percent ;

-- 6 Average Rating
seLECT ROUND(AVG(ratings_given), 1) AS average_rating  FROM fact_bookings  WHERE ratings_given IN (1,2,3,4,5);

-- 7 No of days
SELECT COUNT(DISTINCT date) AS total_days
FROM dim_date;

-- 8 Total cancelled bookings
select count(*) from fact_bookings where booking_status ='Cancelled' ;

-- 9 Cancellation %
SELECT 
    ROUND((COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) * 100.0) / COUNT(*), 2) AS cancellation_percentage
FROM fact_bookings;

-- 10 Total Checked Out
select count(*) from fact_bookings where booking_status= 'Checked out';

-- 11 Total no show bookings
select count(*) from fact_bookings where booking_status= 'no Show';

-- 12 No Show rate
SELECT 
    ROUND((COUNT(CASE WHEN booking_status = 'No Show' THEN 1 END) * 100.0) 
    / COUNT(*), 2) AS no_show_percentage
FROM fact_bookings;


-- 13Booking % by Platform
SELECT 
    booking_platform, 
    COUNT(booking_platform) AS total_bookings,
    (COUNT(booking_platform) * 100.0) / (SELECT COUNT(*) FROM fact_bookings) AS booking_percentage
FROM fact_bookings
GROUP BY booking_platform
ORDER BY booking_percentage DESC;

-- 14 Booking % by Room class
SELECT 
  room_category ,
  count(room_category) as rooms ,
  count(room_category)*100.0/ (SELECT COUNT(*) FROM fact_bookings) as `Booking % by Room class`
FROM fact_bookings
GROUP BY room_category
;

-- 15 ADR 
SELECT 
    SUM(revenue_generated) / COUNT(*) AS ADR
FROM fact_bookings;

-- 16  Realization_Percentage
SELECT 
    100 - (
        (COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*)) + 
        (COUNT(CASE WHEN booking_status = 'No Show' THEN 1 END) * 100.0 / COUNT(*))
    ) AS Realization_Percentage
FROM fact_bookings;


-- 17 RevPAR
SELECT 
      SUM(fb.revenue_generated) / SUM(dr.capacity) AS RevPAR
FROM fact_bookings fb
JOIN fact_aggregated_bookings dr ON fb.property_id =dr.property_id;

-- 18 DBRN

SELECT COUNT(*) / COUNT(DISTINCT booking_date) AS DBRN
FROM fact_bookings;
 -- 19 DSRN 

 SELECT 
    SUM(fa.capacity) / COUNT(DISTINCT fb.booking_date) AS DSRN
FROM fact_aggregated_bookings fa join fact_bookings fb  on fb.property_id =fa.property_id ;
-- 20 
SELECT 
    SUM(checkout_date) / COUNT(DISTINCT booking_date) AS DURN
FROM fact_bookings;

-- 21 Revenue WoW change %
SELECT 
    cur.week_number, 
    cur.year_number,
    cur.revenue_generated AS current_week_revenue,
    prev.revenue_generated AS previous_week_revenue,
    ((cur.revenue_generated - prev.revenue_generated) / NULLIF(prev.revenue_generated, 0)) * 100 AS WoW_Change_Percentage
FROM 
    (SELECT YEAR(booking_date) AS year_number, WEEK(booking_date) AS week_number, 
            SUM(revenue_generated) AS revenue_generated
     FROM fact_bookings
     GROUP BY YEAR(booking_date), WEEK(booking_date)) cur
LEFT JOIN 
    (SELECT YEAR(booking_date) AS year_number, WEEK(booking_date) AS week_number, 
            SUM(revenue_generated) AS revenue_generated
     FROM fact_bookings
     GROUP BY YEAR(booking_date), WEEK(booking_date)) prev
ON cur.year_number = prev.year_number AND cur.week_number = prev.week_number + 1  order by week_number;
