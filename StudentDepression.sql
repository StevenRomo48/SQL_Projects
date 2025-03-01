-- Data Cleaning

-- Data retrieved from Kaggle (https://www.kaggle.com/datasets/hopesb/student-depression-dataset/data)
-- License Apache 2.0

-- First step will be to create a staging table to work in so the raw data is kept in tact
SELECT *
FROM student_depression;

CREATE TABLE depression_staging
LIKE student_depression;

-- Next step is to insert the data
INSERT depression_staging
SELECT *
FROM student_depression;

-- And we check to see if inserted properly
SELECT *
FROM depression_staging;

-- Now that we have a workspace let's check for duplicates
SELECT 
	COUNT(id)
FROM depression_staging;
-- The above query tells us there are 27898 students 
-- Now let's check for distinct id's
SELECT 
	COUNT(DISTINCT(id))
FROM depression_staging;
-- The output is still 27898 so there are no duplicates 

-- An alternative way to check in MySQL is to assign row numbers to every student
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `id`, `City`, `Age`, `CGPA`, `Study Satisfaction`, `Dietary Habits`, `Degree`) AS row_num
FROM depression_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `id`, `City`, `Age`, `CGPA`, `Study Satisfaction`, `Dietary Habits`, `Degree`) AS row_num
FROM depression_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- This cte shows that no row has a number greater than 1 meaning there are no duplicates

-- Next is to standardize the data 
-- the first thing I notice is to rename the columns so that they're easily readable
SELECT *
FROM depression_staging;

ALTER TABLE depression_staging
RENAME COLUMN Gender TO gender;

ALTER TABLE depression_staging
CHANGE COLUMN Age age int,
CHANGE COLUMN City city text,
CHANGE COLUMN Profession profession text,
CHANGE COLUMN `Academic Pressure` academic_pressure int,
CHANGE COLUMN `Work Pressure` work_pressure int,
CHANGE COLUMN `Study Satisfaction` study_satisfaction int,
CHANGE COLUMN `Job Satisfaction` job_satisfaction int,
CHANGE COLUMN `Sleep Duration` sleep_duration text,
CHANGE COLUMN `Dietary Habits` dietary_habits text,
CHANGE COLUMN Degree degree text,
CHANGE COLUMN `Have you ever had suicidal thoughts ?` suicidal_thoughts text,
CHANGE COLUMN `Work/Study Hours` study_hours int,
CHANGE COLUMN `Financial Stress` financial_stress int,
CHANGE COLUMN `Family History of Mental Illness` family_history text,
CHANGE COLUMN Depression depression text;

-- I started this renaming process with RENAME COLUMN but that function doesn't allow multiple expressions in the same query
-- So I pivoted to CHANGE COLUMN to put all the new column names into one query

-- Let's check the data in every column to make sure everything is relevant and that there are no NULLS

SELECT DISTINCT(gender),
COUNT(gender) AS total
FROM depression_staging
GROUP BY gender;
-- this column is good

SELECT DISTINCT(age),
COUNT(age) AS total
FROM depression_staging
GROUP BY age
ORDER BY age ASC;
-- There is a drop off in count after age 34. Only 49 instances over the age of 34

SELECT DISTINCT(city),
COUNT(city) AS total
FROM depression_staging
GROUP BY city
ORDER BY total DESC;
-- There are a few cities with low count but no NULLs 

SELECT DISTINCT(profession),
COUNT(profession) AS total
FROM depression_staging
GROUP BY profession;

SELECT *
FROM depression_staging
WHERE profession != 'Student';
-- 31 non students out of 27898 can be deleted due to low count and the fact that they're not students and we're looking at student data

START TRANSACTION;
	DELETE
    FROM depression_staging
    WHERE profession != 'Student';
COMMIT;

SELECT DISTINCT(academic_pressure),
COUNT(academic_pressure) AS total
FROM depression_staging
GROUP BY academic_pressure;

SELECT *
FROM depression_staging
WHERE academic_pressure = 0;
-- There are 9 here, since this is a subjective column the low count can stay

SELECT DISTINCT(work_pressure),
COUNT(work_pressure) AS total
FROM depression_staging
GROUP BY work_pressure;
-- 3 instances over 0, this entire column can be deleted due to low count and irrelevance

START TRANSACTION;
	ALTER TABLE depression_staging
    DROP COLUMN work_pressure;
COMMIT;

SELECT CGPA
FROM depression_staging
ORDER BY CGPA ASC;
-- there are 9 '0' values here but I'm going to keep them because the student could just be failing

SELECT DISTINCT(study_satisfaction),
COUNT(study_satisfaction) AS total
FROM depression_staging
GROUP BY study_satisfaction;
-- the 10 '0' values here are okay even with low count because this column is subjective

SELECT DISTINCT(job_satisfaction),
COUNT(job_satisfaction) AS total
FROM depression_staging
GROUP BY job_satisfaction;
-- only 8 instances above 0 this column can be deleted due to irrelevance and low count

START TRANSACTION;
	ALTER TABLE depression_staging
    DROP COLUMN job_satisfaction;
COMMIT;

SELECT DISTINCT(sleep_duration),
COUNT(sleep_duration) AS total
FROM depression_staging
GROUP BY sleep_duration;
-- Others has 18, those can be deleted

START TRANSACTION;
	DELETE
    FROM depression_staging
    WHERE sleep_duration = 'Others';
COMMIT;

SELECT DISTINCT(dietary_habits),
COUNT(dietary_habits) AS total
FROM depression_staging
GROUP BY dietary_habits;
-- 12 'others' these can be deleted due to low count

START TRANSACTION;
	DELETE
    FROM depression_staging
    WHERE dietary_habits = 'Others';
COMMIT;

SELECT DISTINCT(degree),
COUNT(degree) AS total
FROM depression_staging
GROUP BY degree;
-- there are 'others' here as well but I believe this is okay for this column due to the multiple options that could possibly be the degree

SELECT DISTINCT(suicidal_thoughts),
COUNT(suicidal_thoughts) AS total
FROM depression_staging
GROUP BY suicidal_thoughts;
-- this column is good

SELECT DISTINCT(study_hours),
COUNT(study_hours) AS total
FROM depression_staging
GROUP BY study_hours;
-- this column is good

SELECT DISTINCT(financial_stress),
COUNT(financial_stress) AS total
FROM depression_staging
GROUP BY financial_stress;
-- This column is good

SELECT DISTINCT(family_history),
COUNT(family_history) AS total
FROM depression_staging
GROUP BY family_history;
-- this column is good

SELECT DISTINCT(depression),
COUNT(depression) AS total
FROM depression_staging
GROUP BY depression;
-- this column is good except for it's format

-- The depression column is the only boolean column not in that format, so let's update it to standardize the data 
START TRANSACTION;
	UPDATE depression_staging
    SET depression = 'Yes'
    WHERE depression = '1';
    
    UPDATE depression_staging
    SET depression = 'No'
    WHERE depression = '0';
COMMIT;
-- Doing updates inside a transaction can allow you to easily recover data after a potential mistake

-- Let's see how many instances we have after those changes
SELECT 
	COUNT(DISTINCT(id))
FROM depression_staging;
-- 27,837

SELECT *
FROM depression_staging;

SELECT LENGTH(age)
FROM depression_staging
WHERE LENGTH(age) != 2;

-- I found no other inconsistencies such as data that needs to be TRIMMED, and every data type is correct as well. 
-- There are also no NULL or blank values 
-- I can conclude that this data is cleaned and ready for EDA (exploratory data analysis)

