/* =================================================================
 File: 01_Schemas.sql
 Purpose: Creates all 6 tables for the Meridian Health database,
         including primary/foreign key relationships.
 Run order: 1st (before any other script)
 Author: Arsalan Gulzar
 Project:Healthcare Readmissions Analysis
 ==================================================================*/
IF OBJECT_ID('dbo.departments', 'U') IS NOT NULL DROP TABLE dbo.departments;
CREATE TABLE dbo.departments
(
	department_id   INT PRIMARY KEY,
	name            VARCHAR(50),
	bed_capacity    INT,
	avg_staff_ratio DECIMAL(4,1)
);

IF OBJECT_ID('dbo.patients', 'U') IS NOT NULL DROP TABLE dbo.patients;
CREATE TABLE dbo.patients
(

    patient_id         INT PRIMARY KEY,
    first_name         VARCHAR(40),
    last_name          VARCHAR(40),
    dob                DATE,
    sex                CHAR(1),
    zip_code           VARCHAR(20),
    insurance_type     VARCHAR(30)
);

IF OBJECT_ID('dbo.admissions', 'U') IS NOT NULL DROP TABLE dbo.admissions;
CREATE TABLE dbo.admissions 
(
    admission_id             INT PRIMARY KEY,
    patient_id               INT FOREIGN KEY REFERENCES dbo.patients(patient_id),
    admit_date               DATE,
    discharge_date           DATE NULL,     
    admit_type               VARCHAR(20),    -- ER / Elective / Transfer
    department               VARCHAR(50),   
    attending_physician_id   VARCHAR(10),
    er_boarding_minutes      INT NULL       -- only populated for ER admits
);

IF OBJECT_ID('dbo.diagnoses', 'U') IS NOT NULL DROP TABLE dbo.diagnoses;
CREATE TABLE dbo.diagnoses 
(
    diagnosis_id     INT IDENTITY(1,1) PRIMARY KEY,
    admission_id     INT FOREIGN KEY REFERENCES dbo.admissions(admission_id),
    icd10_code       VARCHAR(10),
    diagnosis_desc   VARCHAR(150),
    is_primary       BIT
);

IF OBJECT_ID('dbo.billing', 'U') IS NOT NULL DROP TABLE dbo.billing;
CREATE TABLE dbo.billing 
(
    admission_id     INT PRIMARY KEY FOREIGN KEY REFERENCES dbo.admissions(admission_id),
    total_charge     DECIMAL(10,2),
    insurance_paid   DECIMAL(10,2),
    patient_paid     DECIMAL(10,2),
    length_of_stay   INT
);

IF OBJECT_ID('dbo.readmissions_reference', 'U') IS NOT NULL DROP TABLE readmissions_reference;
CREATE TABLE dbo.readmissions_reference
(
    original_admission_id     INT,
    readmission_admission_id  INT,
    days_between               INT
);

GO
