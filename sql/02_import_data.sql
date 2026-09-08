/* =================================================================
 File: 02_import_data.sql
 Purpose: Loads CSV data into staging tables, then inserts cleaned
          staging data into the final schema tables.
 Run order: 2nd (after 01_Schemas.sql)
 Author: Arsalan Gulzar
 Project:Healthcare Readmissions Analysis
 ==================================================================*/

INSERT INTO dbo.departments
(
	department_id ,
	name ,
	bed_capacity ,
	avg_staff_ratio
)
SELECT 
	department_id , 
	name , 
	bed_capacity , 
	avg_staff_ratio
FROM dbo.departments_staging;

DROP TABLE dbo.departments_staging;


INSERT INTO dbo.patients
(
	patient_id,
	first_name,
	last_name,
	dob,
	sex,
	zip_code,
	insurance_type
)
SELECT 
	patient_id,
	first_name,
	last_name,
	dob,
	sex,
	zip_code,
	insurance_type
FROM dbo.patients_staging;

DROP TABLE dbo.patients_staging;

INSERT INTO dbo.admissions
(
	admission_id,
	patient_id,
	admit_date,
	discharge_date,
	admit_type,
	department,
	attending_physician_id,
	er_boarding_minutes
)
SELECT
	admission_id,
	patient_id,
	admit_date,
	discharge_date,
	admit_type,
	department,
	attending_physician_id,
	er_boarding_minutes
FROM dbo.admissions_staging;

DROP TABLE dbo.admissions_staging;

INSERT INTO dbo.billing
(
	admission_id,
	total_charge,
	insurance_paid,
	patient_paid,
	length_of_stay
)
SELECT 
	admission_id,
	total_charge,
	insurance_paid,
	patient_paid,
	length_of_stay
FROM dbo.billing_staging ;

DROP TABLE dbo.billing_staging;


INSERT INTO dbo.diagnoses
(
    admission_id,
	icd10_code,
	diagnosis_desc,
	is_primary
)
SELECT 
	admission_id,
	icd10_code,
	diagnosis_desc,
	is_primary
FROM dbo.diagnoses_staging;

DROP TABLE dbo.diagnoses_staging;


INSERT INTO dbo.readmissions_reference
(
    original_admission_id,
	readmission_admission_id,
	days_between
)
SELECT 
	original_admission_id,
	readmission_admission_id,
	days_between
FROM dbo.readmissions_staging;

DROP TABLE readmissions_staging;

-- Quick sanity check after loading
SELECT 'departments' AS tbl, COUNT(*) AS row_count FROM dbo.departments
UNION ALL SELECT 'patients', COUNT(*) FROM dbo.patients
UNION ALL SELECT 'admissions', COUNT(*) FROM dbo.admissions
UNION ALL SELECT 'diagnoses', COUNT(*) FROM dbo.diagnoses
UNION ALL SELECT 'billing', COUNT(*) FROM dbo.billing
UNION ALL SELECT 'readmissions_reference', COUNT(*) FROM dbo.readmissions_reference;
