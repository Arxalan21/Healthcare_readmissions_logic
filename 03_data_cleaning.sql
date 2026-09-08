-- ============================================================
-- Data Cleaning Tasks
-- ============================================================

-- 1. Standardize department names (messy casing/spelling/abbreviations)

UPDATE dbo.admissions
SET department = CASE
    WHEN LOWER(LTRIM(RTRIM(department)))  LIKE 'card%'                              THEN 'Cardiology'
    WHEN LOWER(LTRIM(RTRIM(department)))  IN ('ER' , 'emergency', 'emergency dept') THEN 'Emergency'
    WHEN LOWER(LTRIM(RTRIM(department)))  LIKE 'ortho%'                             THEN 'Orthopedics'
    WHEN LOWER(LTRIM(RTRIM(department)))  LIKE  'onc%'                              THEN 'Oncology'
    WHEN LOWER(LTRIM(RTRIM(department)))  LIKE 'gen%med%'                           THEN 'General Medicine'
    WHEN LOWER(LTRIM(RTRIM(department)))  LIKE 'pulm%'                              THEN 'Pulmonology'
    ELSE LOWER(LTRIM(RTRIM(department)))
END ;

-- 2. Standardize insurance types

UPDATE dbo.patients
SET insurance_type = CASE
    WHEN LOWER(LTRIM(RTRIM(insurance_type))) = 'uninsured' THEN 'Uninsured'
    WHEN LOWER(LTRIM(RTRIM(insurance_type))) = 'medicare' THEN 'Medicare'
    WHEN LOWER(LTRIM(RTRIM(insurance_type))) = 'medicaid' THEN 'Medicaid'
    WHEN LOWER(LTRIM(RTRIM(insurance_type))) IN ( 'self-pay' , 'self pay') THEN 'Self-Pay'
    WHEN LOWER(LTRIM(RTRIM(insurance_type))) = 'private' THEN 'Private'
    ELSE  LOWER(LTRIM(RTRIM(insurance_type)))
END;

-- 3. Flag open encounters (no discharge date)
SELECT COUNT(*) AS open_encounters
FROM dbo.admissions
WHERE discharge_date IS NULL;

IF COL_LENGTH('dbo.admissions' , 'is_open_encounter') IS NULL
   ALTER TABLE dbo.admissions ADD is_open_encounter BIT NOT NULL DEFAULT 0;

UPDATE dbo.admissions
SET is_open_encounter = 1
WHERE discharge_date IS NULL;


-- 4. Flag invalid ICD-10 codes
-- Basic format check: 1 letter + 2 digits, optional decimal + 1-4 alphanumeric
IF COL_LENGTH('dbo.diagnoses' , 'is_valid_icd10') IS NULL
ALTER TABLE dbo.diagnoses ADD is_valid_icd10 BIT NOT NULL DEFAULT 1

UPDATE dbo.diagnoses
SET is_valid_icd10 = 0
WHERE icd10_code NOT LIKE '[A-Z][0-9][0-9]'
  AND icd10_code NOT LIKE '[A-Z][0-9][0-9].[0-9A-Z]'
  AND icd10_code NOT LIKE '[A-Z][0-9][0-9].[0-9A-Z][0-9A-Z]'
  AND icd10_code NOT LIKE '[A-Z][0-9][0-9].[0-9A-Z][0-9A-Z][0-9A-Z]'
  AND icd10_code NOT LIKE '[A-Z][0-9][0-9].[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]';

-- 5. Flag outlier length-of-stay values (negative or implausibly long)
IF COL_LENGTH('dbo.admissions','los_flag') IS NULL
ALTER TABLE dbo.admissions ADD los_flag VARCHAR(20) NULL;

UPDATE dbo.admissions
SET los_flag = CASE
    WHEN discharge_date IS NULL THEN 'OPEN'
    WHEN discharge_date < admit_date THEN 'NEGATIVE_LOS'
    WHEN DATEDIFF(DAY,admit_date ,discharge_date ) > 180 THEN 'EXTREME_LOS'
    ELSE 'OK'
END;

-- 6. De-duplicate patients on (first_name, last_name, dob) — keep lowest patient_id
-- Step 1: inspect duplicates before deleting anything

WITH duplicates AS 
(
    SELECT 
        patient_id,
        ROW_NUMBER() OVER(PARTITION BY first_name , last_name , dob ORDER BY patient_id) AS rn
    FROM dbo.patients
)

SELECT p.*
FROM dbo.patients p
JOIN duplicates d ON d.patient_id = p.patient_id
WHERE d.rn > 1
ORDER BY p.first_name , p.last_name;


