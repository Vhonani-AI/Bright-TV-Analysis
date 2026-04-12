-- 1. DATA QUALITY CHECK – VIEWERSHIP
----------------------------------------
-- Data Preview
SELECT * 
FROM `brightlearn`.`case_study`.`bright_tv_viewership`
LIMIT 10;


-- Check for extra values (none/other/unknown)
SELECT DISTINCT *
FROM `brightlearn`.`case_study`.`bright_tv_viewership`;


-- Check for duplicate sessions
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


-- Check dirty categorical values
SELECT DISTINCT * 
FROM `brightlearn`.`case_study`.`bright_tv_user_profiles`;


-- Check duplicate users
SELECT 
    UserID,
    COUNT(*) AS row_count
FROM `brightlearn`.`case_study`.`bright_tv_user_profiles`
GROUP BY UserID
HAVING COUNT(*) > 1;


-- 4. FINAL CLEAN TABLE: bright_television
----------------------------------------
CREATE OR REPLACE TABLE `brightlearn`.`case_study`.`bright_television` AS
SELECT
    v.UserID AS user_id,
    v.Channel2 AS channel,

    -- Convert UTC to SA time
    v.RecordDate2 + INTERVAL 2 HOURS AS sa_datetime,

    DATE(v.RecordDate2 + INTERVAL 2 HOURS) AS watch_date,
    DATE_FORMAT(v.RecordDate2 + INTERVAL 2 HOURS, 'HH:mm:ss') AS watch_time,
    DATE_FORMAT(v.RecordDate2 + INTERVAL 2 HOURS, 'EEEE') AS day_name,
    DATE_FORMAT(v.RecordDate2 + INTERVAL 2 HOURS, 'MMMM') AS month_name,
    HOUR(v.RecordDate2 + INTERVAL 2 HOURS) AS hour,

    -- Time of day grouping
    CASE 
        WHEN HOUR(v.RecordDate2 + INTERVAL 2 HOURS) BETWEEN 0 AND 5 THEN 'Late Night'
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

    -- Clean Gender
    CASE 
        WHEN u.Gender = 'None' OR u.Gender = '' THEN 'Unknown'
        ELSE u.Gender
    END AS gender,

    -- Clean Race
    CASE 
        WHEN u.Race = 'None' OR u.Race = 'Other' OR u.Race = 'Unknown' OR u.Race = '' THEN 'Unknown'
        ELSE u.Race
    END AS race,

    -- Clean Age
    CASE 
        WHEN u.Age = 0 THEN NULL
        ELSE u.Age
    END AS age,

    -- Clean Province
    CASE 
        WHEN u.Province = 'None' OR u.Province = 'Unknown' OR u.Province = '' THEN 'Unknown'
        ELSE u.Province
    END AS province,

    -- Age grouping
    CASE 
        WHEN u.Age BETWEEN 1 AND 17 THEN 'Children'
        WHEN u.Age BETWEEN 18 AND 29 THEN 'Young Adults'
        WHEN u.Age BETWEEN 30 AND 44 THEN 'Adults'
        WHEN u.Age >= 45 THEN 'Seniors'
        ELSE 'Unknown'
    END AS age_group

FROM `brightlearn`.`case_study`.`bright_tv_viewership` AS v
LEFT JOIN `brightlearn`.`case_study`.`bright_tv_user_profiles` AS u
ON v.UserID = u.UserID;


-- 5. VALIDATE FINAL TABLE
----------------------------------------
SELECT *
FROM `brightlearn`.`case_study`.`bright_television`;


SELECT COUNT(*) AS total_records
FROM `brightlearn`.`case_study`.`bright_television`;


SELECT COUNT(DISTINCT user_id) AS total_users
FROM `brightlearn`.`case_study`.`bright_television`;


-- 6. PLATFORM OVERVIEW
----------------------------------------
SELECT COUNT(DISTINCT user_id) AS total_users
FROM `brightlearn`.`case_study`.`bright_television`;

--- 4386

SELECT COUNT(*) AS total_sessions
FROM `brightlearn`.`case_study`.`bright_television`;

--- 10000

-- 7. USER ANALYSIS
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


-- 8. USAGE ANALYSIS
----------------------------------------
SELECT time_of_day, COUNT(*) AS sessions
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY time_of_day
ORDER BY sessions DESC;

--- evening, afternoon, midday

SELECT day_name, COUNT(*) AS sessions
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY day_name
ORDER BY sessions DESC;

--- top3: fri, sat, wed

-- 9. CONTENT ANALYSIS
----------------------------------------
SELECT channel, COUNT(*) AS total_views
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY channel
ORDER BY total_views DESC;

--- Top3: Supersport Live Events, ICC Cricket World Cup 2011, Channel O 

SELECT channel, SUM(duration_minutes) AS total_watch_time
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY channel
ORDER BY total_watch_time DESC;


-- 10. CONSUMPTION DRIVERS
----------------------------------------
SELECT age_group, SUM(duration_minutes) AS watch_time
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY age_group
ORDER BY watch_time DESC;

--- max: adults,young adults, seniors

SELECT gender, SUM(duration_minutes) AS watch_time
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY gender;

--- max:male

SELECT time_of_day, AVG(duration_minutes) AS avg_duration
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY time_of_day;

--- 

SELECT time_of_day, SUM(duration_minutes) AS total_duration
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY time_of_day;

--- max: afternoon & min:morning

-- 11. LOW CONSUMPTION ANALYSIS
----------------------------------------
SELECT day_name, COUNT(*) AS sessions
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY day_name
ORDER BY sessions ASC;

--- Friday with 1675 sessions

SELECT day_name, channel, COUNT(*) AS views
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY day_name, channel
ORDER BY day_name, views DESC;

--- Supersport Live Events with 408 views

-- 12. HIGH VALUE USERS 
----------------------------------------
SELECT user_id, SUM(duration_minutes) AS total_watch_time
FROM `brightlearn`.`case_study`.`bright_television`
GROUP BY user_id
ORDER BY total_watch_time DESC;
-- max 789.7166666666666
