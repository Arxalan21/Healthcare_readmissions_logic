# Data Dictionary

Synthetic hospital data generated for portfolio purposes. No real patient
data is used anywhere in this project.

## patients.csv
Patient demographic records.
| Column | Description |
|---|---|
| patient_id | Unique patient identifier |
| first_name, last_name | Patient name |
| dob | Date of birth |
| sex | M/F |
| zip_code | Patient's zip code |
| insurance_type | Raw/uncleaned insurance category (see cleaning script) |

## admissions.csv
One row per hospital admission (encounter).
| Column | Description |
|---|---|
| admission_id | Unique admission identifier |
| patient_id | Links to patients.csv |
| admit_date, discharge_date | Admission dates (discharge_date may be blank for open encounters) |
| admit_type | ER / Elective / Transfer |
| department | Raw/uncleaned department name (see cleaning script) |
| attending_physician_id | Physician code |
| er_boarding_minutes | Only populated for ER admissions |

## diagnoses.csv
One or more rows per admission — the diagnoses recorded for that visit.
| Column | Description |
|---|---|
| admission_id | Links to admissions.csv |
| icd10_code | ICD-10 diagnosis code (a small number are intentionally invalid — see cleaning script) |
| diagnosis_desc | Human-readable diagnosis name |
| is_primary | Whether this was the primary diagnosis for the visit |

## billing.csv
One row per admission — the billing summary.
| Column | Description |
|---|---|
| admission_id | Links to admissions.csv |
| total_charge, insurance_paid, patient_paid | Dollar amounts |
| length_of_stay | Days admitted |

## departments.csv
Reference table of the hospital's 6 departments and their bed capacity.

## readmissions.csv
Reference table showing which admissions were followed by a readmission
within 30 days. Provided for validation — the project also derives this
independently in SQL (see `04_readmissions_logic.sql`).
