-- ============================================================
-- Core Task: Derive 30-Day Readmissions with Window Functions
-- ============================================================

-- Step 1: Clean encounter base (exclude open/invalid LOS encounters)

WITH clean_admissions AS
(
	SELECT 
		admission_id,
		patient_id,
		admit_date,
		discharge_date,
		department
	FROM dbo.admissions
	WHERE los_flag = 'OK'
)
-- Step 2: Use LEAD() to find each patient's NEXT admission date/id
,sequenced AS (
	SELECT
		admission_id,
		patient_id,
		admit_date,
		discharge_date,
		department,
		LEAD(admit_date) OVER(PARTITION BY patient_id ORDER BY admit_date) AS next_admit_date,
		LEAD(admission_id) OVER(PARTITION BY patient_id ORDER BY admit_date) AS next_admission_id
	FROM clean_admissions
)
-- Step 3: Flag readmissions within 30 days of discharge
,flagged AS (
    SELECT *,
		DATEDIFF(DAY, discharge_date , next_admit_date) AS days_to_next_admit,
		CASE 
		    WHEN next_admit_date IS NOT NULL
		    AND DATEDIFF(DAY, discharge_date , next_admit_date) BETWEEN 0 AND 30 THEN 1
		    ELSE 0
		END AS is_readmission_trigger
    FROM sequenced
)
    SELECT 
	   department,
	   COUNT(*) AS total_discharges,
	   SUM(is_readmission_trigger) AS readmissions_30days,
	   CAST(ROUND(100.0 * SUM(is_readmission_trigger) / COUNT(*),2) AS DECIMAL(5,2)) AS readmission_rate_pct
    FROM flagged
    GROUP BY department
    ORDER BY readmission_rate_pct DESC;
