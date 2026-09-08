# Meridian Health — Patient Readmissions & Hospital Operations Analysis

*A healthcare analytics portfolio project analyzing hospital admissions, data
quality, and key operational metrics using T-SQL in SQL Server Management
Studio.*

## 1. Overview

**Business problem:** Meridian Regional Health Network's COO needed
visibility into hospital operations — patient volume, department load,
billing patterns, and 30-day readmission risk — to support decisions around
resourcing and CMS readmission-penalty exposure.

**Stakeholder:** COO, Meridian Regional Health Network

**Objective:** Clean and validate raw hospital data, then calculate
operational KPIs and derive 30-day patient readmissions directly from raw
admission data to give leadership a reliable, evidence-based view of the
hospital system.

## 2. Data

- **Source:** Synthetic dataset generated for portfolio purposes — no real
  patient data was used anywhere in this project.
- **Tables:** `patients`, `admissions`, `diagnoses`, `departments`,
  `billing`, `readmissions_reference`
- **Confirmed row counts (post-load):**

  | Table | Rows |
  |---|---|
  | departments | 6 |
  | patients | 1,215 |
  | admissions | 3,000 |
  | diagnoses | 3,875 |
  | billing | 3,000 |
  | readmissions_reference | 311 |

- **Tool:** SQL Server Management Studio (SSMS), T-SQL

## 3. Process

### Data Loading
Imported all 6 CSV files into SQL Server using SSMS's Import Flat File
wizard, staging each file into a `_staging` table before inserting into the
final schema — a safer pattern that allows row-count verification and
foreign-key validation before touching production tables. Row counts were
confirmed after every load to catch data loss or duplication early (a
foreign-key conflict during the billing load surfaced an incomplete
`admissions` load, which was caught and corrected this way).

### Data Cleaning
The raw data included deliberate real-world messiness. Steps taken:

1. **Standardized department names** — 13 raw spelling/casing variants
   (e.g. `CARDIOLOGY`, `cardiology `, `Cardiolgy`) were collapsed into 6
   clean department names using case-insensitive pattern matching
   (`LIKE` with wildcards).
2. **Standardized insurance type values** — collapsed inconsistent casing
   (`Medicare`, `medicare`, `MEDICARE`, etc.) into 5 clean categories.
3. **Flagged open encounters** — admissions with no discharge date (patient
   still admitted as of the data snapshot) were flagged via an
   `is_open_encounter` column rather than dropped, preserving the record
   while excluding it from length-of-stay calculations.
4. **Flagged invalid ICD-10 codes** — validated code format (1 letter +
   2 digits, optional decimal + 1-4 alphanumeric characters) using pattern
   matching. **10 invalid codes** identified out of 3,875 diagnosis records.
5. **Flagged length-of-stay outliers** — added an `los_flag` column marking
   each admission as `OK`, `OPEN`, `NEGATIVE_LOS` (discharge date before
   admit date — a data entry error), or `EXTREME_LOS` (stay longer than
   180 days).
6. **Identified duplicate patient records** — found 15 patients (~1.2% of
   the patient base) sharing identical first name, last name, and date of
   birth. Rather than auto-deleting these, they were flagged for manual
   review: in a real healthcare system, merging patient identities without
   a reliable unique identifier (SSN/MRN) risks incorrectly combining two
   different people's medical records. Their presence has negligible impact
   on encounter-level KPIs, which are calculated per-admission rather than
   per-patient.

### Analysis
Calculated KPIs ranging from simple aggregations (`COUNT`, `AVG`,
`GROUP BY`) to intermediate multi-table joins (`LEFT JOIN` + `CASE WHEN`)
and an advanced derivation of 30-day patient readmissions using the
`LEAD()` window function — computed directly from raw admission/discharge
dates rather than relying on a pre-supplied answer key.

## 4. Key Findings

### Operational KPIs

1. Total patients on file: **1,215** (includes 15 known duplicates)
2. Busiest department by admission volume: **Cardiology, 718 admissions**
   (followed by Orthopedics 476, General Medicine 465, Emergency 453,
   Oncology 448)
3. Payer mix: **Medicare** is the largest payer at **375 patients (~31%)**,
   followed by Medicaid (252), Private (242), Self-Pay (235), and
   Uninsured (111)
4. Highest average billing charge by department: **Emergency, $8,981.42**
5. Admission type breakdown: **Elective 1,538 (51%), ER 1,210 (40%),
   Transfer 252 (8%)**
6. Average length of stay: **highest in Oncology at 9.49 days**, followed
   by Cardiology (8.09), General Medicine (7.67), Orthopedics (6.09), and
   Pulmonology (5.76)
7. Open encounters (patients still admitted as of data snapshot): **50**
8. Most common primary diagnosis: **Chronic kidney disease, unspecified**
   (319 occurrences), followed by Chest pain, unspecified (313) and
   Fracture of femur, initial encounter (309)

### Cost & Readmissions

9. **Average charge for non-readmitted encounters: $10,776.01** (2,689
   encounters)
10. **Average charge for readmitted encounters: $8,434.56** (311
    encounters)
11. 30-day readmission rate by department: **highest in Cardiology at
    11.35%** (79 of 696 discharges), followed closely by Orthopedics
    (11.16%), Oncology (10.83%), Pulmonology (10.30%), General Medicine
    (10.22%), and lowest in Emergency (8.14%) — a relatively tight spread
    across departments, with no single department standing out as a major
    outlier

Note: in this dataset, non-readmitted encounters actually show a *higher*
average charge than readmitted ones — the reverse of what's typically seen
in real hospital data. Since diagnosis assignment in this dataset was
randomized rather than clinically modeled, this is a property of the
synthetic data generation, not a real clinical signal — see Limitations.

## 5. Recommendations

*(Tie each recommendation directly to a finding above — for example:)*

- Given Cardiology's disproportionately high admission volume (718 vs. the
  next-highest department at 476), consider evaluating staffing and bed
  capacity allocation specifically for that department.
- Cardiology shows both the highest admission volume (718) and the highest
  30-day readmission rate (11.35%) — a natural first candidate for a
  post-discharge follow-up program, since improvements there would affect
  the largest number of patients.
- Oncology has the longest average length of stay (9.49 days); worth
  reviewing whether this reflects case complexity or points to discharge
  planning delays.
- Given the volume of open encounters, ensure discharge-date data entry is
  timely to keep length-of-stay and occupancy metrics accurate going
  forward.

## 6. Limitations

- Data is **synthetic**, not real patient data — patterns and correlations
  shown (including the cost-vs-readmission finding above) are illustrative
  of the SQL technique, not clinically meaningful. Diagnosis codes
  themselves are real ICD-10 codes, but their assignment to patients was
  randomized, with no clinical logic linking diagnosis to outcome or cost.
- No formal risk-adjustment model was applied — CMS's actual Hospital
  Readmissions Reduction Program methodology is significantly more complex
  than the simple 30-day window used here.
- Sample size (~1,200 patients, 3,000 admissions) is small relative to a
  real hospital system's annual volume.
- 15 duplicate patient records were identified but intentionally not
  removed, to avoid the risk of incorrectly merging distinct patient
  identities without a reliable unique identifier.
- 10 diagnosis records had invalid ICD-10 codes and were flagged, not
  corrected, since the correct code couldn't be inferred from available
  data.

## 7. Tools Used

- **T-SQL** (SQL Server Management Studio) — all cleaning, transformation,
  and aggregation performed entirely in-database, including window
  functions (`LEAD()`), CTEs, `CASE WHEN` logic, and joins
  (`INNER`/`LEFT JOIN`)
- Python (pandas, numpy) was used only to generate the synthetic source
  CSVs for this project — no cleaning or analysis logic runs in Python

## 8. How to Reproduce

1. Create a new database in SSMS (e.g. `MeridianHealth`)
2. Run `sql/01_Schemas.sql` to create all 6 tables
3. Import each CSV from the `data/` folder via SSMS's **Tasks → Import Flat
   File** wizard into a `_staging` table, then run the corresponding
   `INSERT INTO ... SELECT ...` statement to load it into the real table
   (see `sql/02_import_data.sql`)
4. Run `sql/03_data_cleaning.sql` to standardize department/insurance
   values and flag data quality issues (open encounters, invalid ICD-10
   codes, LOS outliers)
5. Run `sql/04_readmissions_logic.sql` to derive 30-day readmissions from
   raw admission dates using `LEAD()`
6. Run `sql/05_KPI_Calculations.sql` for the full set of KPI results, from
   simple counts through the readmitted-vs-non-readmitted cost comparison

## File Structure

```
Healthcare_readmissions_logic/
├── README.md
├── sql/
│   ├── 01_Schemas.sql
│   ├── 02_import_data.sql
│   ├── 03_data_cleaning.sql
│   ├── 04_readmissions_logic.sql
│   └── 05_KPI_Calculations.sql
└── data/
    ├── README.md          (data dictionary)
    ├── patients.csv
    ├── admissions.csv
    ├── diagnoses.csv
    ├── readmissions.csv
    ├── departments.csv
    └── billing.csv
```

---
**Data Ethics Note:** This project uses entirely synthetic data generated
for portfolio/learning purposes. No real patient records were used at any
stage.

