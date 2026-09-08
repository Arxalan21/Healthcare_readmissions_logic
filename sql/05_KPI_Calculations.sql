-- total patient count
SELECT 
COUNT(*) AS Total_Patients 
FROM dbo.patients

-- admissions by department
SELECT 
department,
COUNT(*) AS total_admissions
FROM dbo.admissions
GROUP BY department
ORDER BY total_admissions;

--Patient count by insurance type
SELECT 
insurance_type,
COUNT(*) AS Total_patients
FROM dbo.patients
GROUP BY insurance_type
ORDER BY Total_patients

--Average total charge per department
SELECT 
a.department,
ROUND(AVG(b.total_charge),2) AS avg_charge
FROM dbo.admissions a
JOIN dbo.billing b
ON a.admission_id = b.admission_id
GROUP BY a.department
ORDER BY avg_charge

-- admission type background
SELECT 
admit_type,
COUNT(*) AS total
FROM dbo.admissions
GROUP BY admit_type
ORDER BY  total

--Diagnosis frequency
SELECT
diagnosis_desc,
COUNT(*) AS occurences
FROM dbo.diagnoses
GROUP BY diagnosis_desc
ORDER BY occurences DESC

--Cost comparison: Readmitted vs non_readmitted patients
SELECT
CASE
    WHEN r.original_admission_id IS NOT NULL THEN'readmitted' 
    ELSE 'Not_readmitted'
END AS group_label,
ROUND(AVG(b.total_charge),2) AS avg_total_charge,
COUNT(*) AS n_encounters
FROM dbo.billing b
LEFT JOIN
dbo.readmissions_reference r ON r.original_admission_id = b.admission_id
GROUP BY CASE WHEN r.original_admission_id IS NOT NULL THEN'readmitted' 
    ELSE 'Not_readmitted' END;
