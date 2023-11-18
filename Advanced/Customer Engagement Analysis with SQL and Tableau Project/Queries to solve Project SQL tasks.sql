# Date created and Last ran : 11-18-2023 
# Queries written in MySQL Workbench 8.0 to solve the business questions in Customer Engagement Analysis Project
# Customer Engagement Analysis with SQL and Tableau Project

-- TASK 2 : Retrieving Courses Information with SQL
USE 365_database;
SELECT * FROM 365_course_info;-- RESULT SET 46 rows returned 
SELECT * FROM 365_student_learning;  -- RESULT SET 64,458 rows returned 
SELECT * FROM 365_course_ratings; -- RESULT SET  2500 rows returned 

/* 1. Create a CTE that calculates the total minutes watched and the total number of students for each course.
   2. Create another CTE that calculates the average minutes watched for each course by using the result from the previous step
   3. Create a third CTE that calculates the number of ratings and the average rating for each course.
   4. Retrieve the title_ratings result set and save it as sql-task1-courses.csv. */
   
   WITH title_total_minutes AS
(
    SELECT 
        ci.course_id, 
        ci.course_title, 
        ROUND(SUM(sl.minutes_watched), 2) AS total_minutes_watched, 
        COUNT(DISTINCT sl.student_id) AS num_students
    FROM
        365_course_info ci
    JOIN
        365_student_learning sl USING (course_id)
    GROUP BY ci.course_id
),

title_average_minutes AS
(
    SELECT 
        tt.course_id,
        tt.course_title,
        tt.total_minutes_watched,
        ROUND(tt.total_minutes_watched / tt.num_students, 2) AS average_minutes
    FROM
        title_total_minutes tt
),

title_ratings AS
(
    SELECT 
        ci.course_id,
        ci.course_title,
        ttm.total_minutes_watched,
        tam.average_minutes,
        COUNT(cr.course_rating) AS number_of_ratings,
        COALESCE(ROUND(AVG(cr.course_rating), 2), 0) AS average_rating
    FROM
        365_course_info ci
    LEFT JOIN
        365_course_ratings cr USING (course_id)
    LEFT JOIN
        title_average_minutes tam USING (course_id)
    LEFT JOIN
        title_total_minutes ttm USING (course_id)
    GROUP BY ci.course_id
)

-- Retrieve the title_ratings result set and save it as sql-task1-courses.csv
SELECT * FROM title_ratings          -- 46 rows returned
INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\sql-task1-courses.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- SHOW VARIABLES LIKE "secure_file_priv";

/*  TASK 3 Retrieving Purchases Information with SQL */

-- Drops the purchases_info view if it exists
DROP VIEW IF EXISTS purchases_info;

-- Creates the purchases_info view
CREATE VIEW purchases_info AS
    SELECT 
        purchase_id,
        student_id,
        purchase_type,
        date_purchased AS date_start,
        CASE
            WHEN purchase_type = 'Monthly' THEN DATE_ADD(date_purchased, INTERVAL 1 MONTH)
            WHEN purchase_type = 'Quarterly' THEN DATE_ADD(date_purchased, INTERVAL 3 MONTH)
            WHEN purchase_type = 'Annual' THEN DATE_ADD(date_purchased, INTERVAL 1 YEAR)
        END AS date_end
    FROM
        365_student_purchases;

/* TASK 3 : Retrieving Students Information with SQL */ 

-- Create a temporary table (subquery a) by joining 365_student_info and 365_student_learning tables
-- Calculate the total minutes watched per day and the onboarded status
CREATE TEMPORARY TABLE a AS
    SELECT 
        i.student_id,
        i.student_country,
        i.date_registered,
        l.date_watched,
        IFNULL(SUM(l.minutes_watched), 0) AS minutes_watched,
        IF(l.student_id IS NULL, 0, 1) AS onboarded
    FROM
        365_student_info i
    LEFT JOIN
        365_student_learning l USING (student_id)
    GROUP BY i.student_id, l.date_watched;
-- 81532 rows returned

-- Create another temporary table (subquery b) by joining subquery a with purchases_info view
-- Calculate the paid status based on the date_watched column
CREATE TEMPORARY TABLE b AS
    SELECT 
        a.*,
        IF(p.student_id IS NOT NULL AND a.date_watched BETWEEN p.date_start AND p.date_end, 1, 0) AS paid
    FROM
        a
    LEFT JOIN
        purchases_info p USING (student_id);
-- 104,654 rows returned 
select * from b;
-- Retrieve the final result set and save it as sql-task3-courses.csv
SELECT 
    b.student_id,
    b.student_country,
    b.date_registered,
    b.date_watched,
    b.minutes_watched,
    b.onboarded,
    MAX(b.paid) AS paid
INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\sql-task3-courses.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM b
GROUP BY b.student_id, b.student_country, b.date_registered, b.date_watched, b.minutes_watched, b.onboarded;

-- Result: 81532 records written into sql-task3-courses.csv
