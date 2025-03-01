-- Exploratory Data Analysis for Student Depression Data
-- My objective here is to find which factors contribute to depression in students 

SELECT *
FROM depression_staging;

-- First let's find out how many students in the data set are depressed
SELECT depression, COUNT(*) AS total_depressed
FROM depression_staging
GROUP BY depression;
-- 16,290 YES and 11,547 NO

SELECT COUNT(*)
FROM depression_staging;
-- the full count of students is 27,837

SELECT depression, COUNT(*) AS total_depressed, COUNT(*) / 27837 * 100 AS percentage
FROM depression_staging
GROUP BY depression;
-- 58.5% of the students are depressed let's find out why 

-- Let's create a table that filters for only the depressed students (didn't add this until later and is first used in the Study Hours portion)
CREATE TABLE depressed_students
SELECT *
FROM depression_staging
WHERE depression = 'Yes';
-- Check to see if it ran properly
SELECT *
FROM depressed_students;
-- It did

-- Let's see if Family History plays a role 
WITH family_yes AS
(
SELECT *
FROM depression_staging
WHERE family_history = 'Yes'
AND depression = 'Yes'
)
SELECT COUNT(*), COUNT(*)/16290 * 100 AS percentage
FROM family_yes;
-- 8,250 of the students who are depressed have it in their family history
-- And just over 50% of depressed students have it in their family history 

-- Let's look at academic pressure 
WITH school_pressure AS
(
SELECT *
FROM depression_staging
WHERE academic_pressure = 5
OR academic_pressure = 4
AND depression = 'Yes'
)
SELECT COUNT(*), COUNT(*)/16290 * 100 AS percentage
FROM school_pressure;
-- 63% of depressed students have an academic pressure rating of either 4 or 5 on a scale of 1-5

-- Let's look at Average CGPA
SELECT AVG(CGPA), MAX(CGPA), MIN(CGPA)
FROM depression_staging;

SELECT COUNT(id) AS num_of_students
FROM depression_staging
WHERE CGPA > 7.656
AND depression = 'Yes';
-- 8,689 depressed above average performing students
SELECT COUNT(id) AS num_of_students
FROM depression_staging
WHERE CGPA < 7.656
AND depression = 'Yes';
-- 7,601 depressed below average performing students 
-- The correlation isn't strong enough to say that higher performance is related to depression

-- Next let's look at dietary habits
WITH depressed_students AS
(
SELECT *
FROM depression_staging
WHERE depression = 'Yes'
)
SELECT DISTINCT(dietary_habits),
COUNT(*) OVER(PARTITION BY dietary_habits)
FROM depressed_students;

WITH depressed_students AS
(
SELECT *
FROM depression_staging
WHERE depression = 'No'
)
SELECT DISTINCT(dietary_habits),
COUNT(*) OVER(PARTITION BY dietary_habits)
FROM depressed_students;
-- running both of these queries show that 70% of the students with an unhealthy diet are depressed

-- Let's do the same for sleep duration 
SELECT DISTINCT(sleep_duration),
COUNT(*) OVER(PARTITION BY sleep_duration)
FROM depression_staging;
-- this shows that less than 5 hours of sleep has the most total students

WITH depressed_students AS
(
SELECT *
FROM depression_staging
WHERE depression = 'No'
)
SELECT DISTINCT(sleep_duration),
COUNT(*) OVER(PARTITION BY sleep_duration)
FROM depressed_students;
-- Pretty even distrubution for non-depressed students

WITH depressed_students AS
(
SELECT *
FROM depression_staging
WHERE depression = 'Yes'
)
SELECT DISTINCT(sleep_duration),
COUNT(*) OVER(PARTITION BY sleep_duration)
FROM depressed_students;
-- Less than 5 hours of sleep has the most depressed students

WITH low_sleep AS
(
SELECT *
FROM depression_staging
WHERE sleep_duration = 'Less than 5 hours'
OR sleep_duration = '5-6 hours'
AND depression = 'Yes'
)
SELECT COUNT(*), COUNT(*)/16290 * 100 AS percentage
FROM low_sleep;
-- 72% of depressed students get less than the recommended 7-8 hours of sleep 

-- Let's see if there is a difference by gender
SELECT gender, COUNT(*) AS total_students, 15511/27837 *100 AS male_percent, 12326/27837 *100 AS female_percent
FROM depression_staging
GROUP BY gender;
-- There are 15,511 male students in the study or 56% and 12,326 female students or 44%
-- Let's see if the percentage of depressed students correlates with those differences

WITH depressed_students AS
(
SELECT *
FROM depression_staging
WHERE depression = 'Yes'
)
SELECT gender, COUNT(*) AS total_depressed, 9091/16290 *100 AS male_dep_percent, 7199/16290 *100 AS female_dep_percent
FROM depressed_students
GROUP BY gender;
-- The percentages line up exactly at 56% for males and 44% for females. So gender does not play a role in having depression 

-- Let's look at age next
WITH depressed_students AS
(
SELECT *
FROM depression_staging
WHERE depression = 'Yes'
)
SELECT age, COUNT(*)
FROM depressed_students
GROUP BY age
ORDER BY 2 DESC;
-- 20 and 24 year olds have the most with over 1500 depressed students. The younger students (<30) tend to be more depressed than the older students

-- Study Hours
WITH study_hours_breakdown AS
(
SELECT depressed_students.study_hours,
COUNT(depressed_students.id) AS depressed,
(SELECT COUNT(*) FROM depressed_students) AS total_students,
COUNT(depressed_students.id)/(SELECT COUNT(*) FROM depressed_students) *100 AS percent_depressed
FROM depressed_students
LEFT JOIN depression_staging 
ON depressed_students.id = depression_staging.id
GROUP BY depressed_students.study_hours
)
SELECT SUM(percent_depressed)
FROM study_hours_breakdown
WHERE study_hours >= 8;

-- The above query shows that 60.6% of depressed students study for 8+ hours a day 

WITH study_hours_breakdown AS
(
SELECT depressed_students.study_hours,
COUNT(depressed_students.id) AS depressed,
(SELECT COUNT(*) FROM depressed_students) AS total_students,
COUNT(depressed_students.id)/(SELECT COUNT(*) FROM depressed_students) *100 AS percent_depressed
FROM depressed_students
LEFT JOIN depression_staging 
ON depressed_students.id = depression_staging.id
GROUP BY depressed_students.study_hours
)
SELECT SUM(percent_depressed)
FROM study_hours_breakdown
WHERE study_hours < 8;

-- And this one shows that 39.4% of depressed students study for less than 8 hours. 
-- We can conclude that higher study hours correlates with depression 

-- Suicidal Thoughts 
SELECT COUNT(*)
FROM depression_staging
WHERE suicidal_thoughts = 'Yes';
-- 17,610 of the students have had suicidal thoughts

WITH dep_thoughts AS
(
SELECT *
FROM depression_staging
WHERE suicidal_thoughts = 'Yes'
AND depression = 'Yes'
)
SELECT COUNT(*)/17610 * 100 AS percentage
FROM dep_thoughts;
-- 79% of students with suicidal thoughts have depression. They are strongly correlated

-- Financial Stress
SELECT financial_stress,
depression,
COUNT(*) 
FROM depression_staging
GROUP BY financial_stress, depression
ORDER BY 1;
-- This query shows that as financial stress increases so does the number of depressed students

WITH money_stress AS
(
SELECT *
FROM depression_staging
WHERE financial_stress >= 4
)
SELECT 
COUNT(*)/12463 * 100 AS percent_depressed
FROM money_stress
WHERE depression = 'Yes';
-- 12463 students have 4 or more financial stress
-- And 75% of those students are depressed meaning there is a positive correlation with financial stress and depression

-- To recap depressed students have:
-- high academic pressure (4+)
-- an unhealthy diet
-- less than 7 hours of sleep
-- under 30 years old
-- study more than 8 hours a day
-- have suicidal thoughts
-- and have high financial stress (4+)

-- Let's see how many students fit all these criteria 
SELECT COUNT(*)
FROM depression_staging
WHERE academic_pressure >= 4
AND dietary_habits = 'Unhealthy'
AND sleep_duration LIKE '%5%'
AND age < 30
AND study_hours >= 8
AND suicidal_thoughts = 'Yes'
AND financial_stress >= 4;
-- 536 Students have each of the factors listed above 
SELECT COUNT(*)
FROM depressed_students
WHERE academic_pressure >= 4
AND dietary_habits = 'Unhealthy'
AND sleep_duration LIKE '%5%'
AND age < 30
AND study_hours >= 8
AND suicidal_thoughts = 'Yes'
AND financial_stress >= 4;
-- And according to this query which filters for depressed students. Only 6 students with all these factors are not depressed
-- Meaning there is a 98.88% chance of being depressed if you have all these factors as a student 






















