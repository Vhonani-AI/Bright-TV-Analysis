-- 1. DATA QUALITY CHECK – VIEWERSHIP
----------------------------------------
-- Data Preview
SELECT * 
FROM `brightlearn`.`case_study`.`bright_tv_viewership`
LIMIT 10;

-- Check distinct values
SELECT DISTINCT Channel2
FROM `brightlearn`.`case_study`.`bright_tv_viewership`;

-- Check duplicate sessions
SELECT 
    UserID, Channel2, RecordDate2, Duration2,
    COUNT(*) AS duplicate_count
FROM `brightlearn`.`case_study`.`bright_tv_viewership`
GROUP BY UserID, Channel2, RecordDate2, Duration2
HAVING COUNT(*) > 1;

-- 2. DATA QUALITY CHECK – USER PROFILES
----------------------------------------
-- Data Preview
SELECT * 
FROM `brightlearn`.`case_study`.`bright_tv_user_profiles`
LIMIT 10;

-- Check distinct categorical values
SELECT DISTINCT Gender, Race, Province
FROM `brightlearn`.`case_study`.`bright_tv_user_profiles`;

-- Check duplicate users
SELECT 
    UserID,
    COUNT(*) AS row_count
FROM `brightlearn`.`case_study`.`bright_tv_user_profiles`
GROUP BY UserID
HAVING COUNT(*) > 1;

-- 3. FINAL CLEAN TABLE: bright_television
----------------------------------------
CREATE OR REPLACE TABLE `brightlearn`.`case_study`.`bright_television` AS
SELECT
    v.UserID AS user_id,
    v.Channel2 AS channel,

    -- Convert UTC to SA time
    v.RecordDate2 + INTERVAL 2 HOURS AS sa_datetime,

    -- Date breakdown
    DATE(v.RecordDate2 + INTERVAL 2 HOURS) AS watch_date,
    DATE_FORMAT(v.RecordDate2 + INTERVAL 2 HOURS, 'EEEE') AS day_name,
    DATE_FORMAT(v.RecordDate2 + INTERVAL 2 HOURS, 'MMMM') AS month_name,
    DATE_FORMAT(v.RecordDate2 + INTERVAL 2 HOURS, 'yyyyMM') AS month_id,
    HOUR(v.RecordDate2 + INTERVAL 2 HOURS) AS hour,

    -- Weekday vs Weekend
    CASE 
        WHEN DATE_FORMAT(v.RecordDate2 + INTERVAL 2 HOURS, 'EEEE') IN ('Saturday','Sunday') 
        THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,

    -- Time of day grouping
    CASE 
        WHEN HOUR(v.RecordDate2 + INTERVAL 2 HOURS) BETWEEN 0 AND 5 THEN 'Early Morning'
        WHEN HOUR(v.RecordDate2 + INTERVAL 2 HOURS) BETWEEN 6 AND 10 THEN 'Morning'
        WHEN HOUR(v.RecordDate2 + INTERVAL 2 HOURS) BETWEEN 11 AND 14 THEN 'Midday'
        WHEN HOUR(v.RecordDate2 + INTERVAL 2 HOURS) BETWEEN 15 AND 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,

    -- Month grouping
    CASE 
        WHEN DAY(v.RecordDate2 + INTERVAL 2 HOURS) BETWEEN 1 AND 10 THEN 'Early Month'
        WHEN DAY(v.RecordDate2 + INTERVAL 2 HOURS) BETWEEN 11 AND 20 THEN 'Mid Month'
        ELSE 'Month End'
    END AS month_period,

    -- Duration in minutes
    (HOUR(v.Duration2)*60) + MINUTE(v.Duration2) + SECOND(v.Duration2)/60 AS duration_minutes,

    -- Consumption Segmentation (by minutes)
    CASE 
        WHEN duration_minutes = 0 THEN 'Dormant'
        WHEN duration_minutes <= 5 THEN 'Light'
        WHEN duration_minutes <= 20 THEN 'Casual'
        WHEN duration_minutes <= 60 THEN 'Engaged'
        ELSE 'Power'
    END AS consumption_segment,

    -- Clean Gender
    CASE 
        WHEN u.Gender = 'None' OR u.Gender = '' THEN 'Unknown'
        ELSE u.Gender
    END AS gender,

    -- Clean Race
    CASE 
        WHEN u.Race IS NULL 
            OR u.Race = '' 
            OR u.Race = 'None'
            OR u.Race = 'Other'
            OR u.Race = 'Unknown'
        THEN 'Unknown'
        ELSE u.Race
    END AS race,

    -- Clean Age
    CASE 
        WHEN u.Age = 0 THEN 'Unknown'
        ELSE CAST(u.Age AS STRING)
    END AS age_clean,

    -- Clean Province
    CASE 
        WHEN u.Province IN ('None','Unknown','') THEN 'Unknown'
        ELSE u.Province
    END AS province,

    -- Age grouping
    CASE 
        WHEN u.Age BETWEEN 1 AND 17 THEN 'Children'
        WHEN u.Age BETWEEN 18 AND 29 THEN 'Youth'
        WHEN u.Age BETWEEN 30 AND 44 THEN 'Adults'
        WHEN u.Age >= 45 THEN 'Seniors'
        ELSE 'Unknown'
    END AS age_group

FROM `brightlearn`.`case_study`.`bright_tv_viewership` AS v
LEFT JOIN `brightlearn`.`case_study`.`bright_tv_user_profiles` AS u
ON v.UserID = u.UserID;


-- 4. PLATFORM OVERVIEW
----------------------------------------
SELECT *
FROM `brightlearn`.`case_study`.`bright_television`;

SELECT COUNT(DISTINCT user_id) AS total_users 
FROM `brightlearn`.`case_study`.`bright_television`;

SELECT COUNT(*) AS total_sessions 
FROM `brightlearn`.`case_study`.`bright_television`;


-- 5. USER ANALYSIS
----------------------------------------
SELECT gender, COUNT(*) AS users 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY gender;

SELECT age_group, COUNT(*) AS users 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY age_group;

SELECT province, COUNT(*) AS users 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY province;


-- 6. USAGE ANALYSIS
----------------------------------------
SELECT time_of_day, COUNT(*) AS sessions 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY time_of_day 
ORDER BY sessions DESC;

SELECT day_name, COUNT(*) AS sessions 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY day_name 
ORDER BY sessions DESC;

-- NEW: Weekday vs Weekend 🔥
SELECT day_type, COUNT(*) AS sessions FROM `brightlearn`.`case_study`.`bright_television` GROUP BY day_type;


-- 7. CONTENT ANALYSIS
----------------------------------------
SELECT channel, COUNT(*) AS total_views 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY channel 
ORDER BY total_views DESC;

SELECT channel, SUM(duration_minutes) AS total_watch_time 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY channel 
ORDER BY total_watch_time DESC;


-- 8. CONSUMPTION DRIVERS
----------------------------------------
SELECT age_group, SUM(duration_minutes) AS watch_time 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY age_group 
ORDER BY watch_time DESC;

SELECT gender, SUM(duration_minutes) AS watch_time 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY gender;

SELECT time_of_day, 
        SUM(duration_minutes) AS total_duration 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY time_of_day;

-- Session behaviour
SELECT session_type, COUNT(*) AS sessions 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY session_type;


-- 9. LOW CONSUMPTION ANALYSIS
----------------------------------------
SELECT day_name, COUNT(*) AS sessions 
FROM `brightlearn`.`case_study`.`bright_television` 
GROUP BY day_name 
ORDER BY sessions ASC;

SELECT day_name, channel, COUNT(*) AS views 
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY day_name, channel
ORDER BY day_name, views DESC;


-- 10. HIGH VALUE USERS
----------------------------------------
SELECT user_id, SUM(duration_minutes) AS total_watch_time
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY user_id
ORDER BY total_watch_time DESC;
