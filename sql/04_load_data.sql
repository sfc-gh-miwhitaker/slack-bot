/*******************************************************************************
 * Step 4: Load Sample Data
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE cortex_agent_slack_role;
USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;

-- Load patients (500 records)
INSERT INTO SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients
WITH first_names AS (
    SELECT column1 AS name, column2 AS gender FROM VALUES
    ('James','Male'),('Mary','Female'),('Robert','Male'),('Patricia','Female'),
    ('John','Male'),('Jennifer','Female'),('Michael','Male'),('Linda','Female'),
    ('David','Male'),('Elizabeth','Female'),('William','Male'),('Barbara','Female'),
    ('Richard','Male'),('Susan','Female'),('Joseph','Male'),('Jessica','Female'),
    ('Thomas','Male'),('Sarah','Female'),('Christopher','Male'),('Karen','Female')
),
last_names AS (
    SELECT column1 AS name FROM VALUES
    ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),
    ('Davis'),('Rodriguez'),('Martinez'),('Hernandez'),('Lopez'),('Gonzalez'),
    ('Wilson'),('Anderson'),('Thomas'),('Taylor'),('Moore'),('Jackson'),('Martin')
),
blood_types AS (
    SELECT column1 AS bt FROM VALUES ('A+'),('A-'),('B+'),('B-'),('AB+'),('AB-'),('O+'),('O-')
),
insurers AS (
    SELECT column1 AS ins FROM VALUES
    ('Blue Cross'),('Aetna'),('UnitedHealth'),('Cigna'),('Humana'),('Kaiser'),('Medicare'),('Medicaid')
),
physicians AS (
    SELECT column1 AS doc FROM VALUES
    ('Dr. Sarah Chen'),('Dr. Michael Roberts'),('Dr. Emily Watson'),('Dr. James Park'),
    ('Dr. Lisa Thompson'),('Dr. Robert Kim'),('Dr. Amanda Garcia'),('Dr. David Lee')
)
SELECT
    ROW_NUMBER() OVER (ORDER BY RANDOM()) AS patient_id,
    f.name AS first_name,
    l.name AS last_name,
    DATEADD('day', -UNIFORM(7300, 29200, RANDOM()), CURRENT_DATE()) AS date_of_birth,
    f.gender,
    bt.bt AS blood_type,
    ins.ins AS insurance_provider,
    doc.doc AS primary_physician
FROM first_names f
CROSS JOIN last_names l
CROSS JOIN (SELECT bt FROM blood_types ORDER BY RANDOM() LIMIT 1) bt
CROSS JOIN (SELECT ins FROM insurers ORDER BY RANDOM() LIMIT 1) ins
CROSS JOIN (SELECT doc FROM physicians ORDER BY RANDOM() LIMIT 1) doc
ORDER BY RANDOM()
LIMIT 500;

-- Randomize patient attributes
UPDATE SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients
SET blood_type = (SELECT bt FROM (SELECT column1 AS bt FROM VALUES ('A+'),('A-'),('B+'),('B-'),('AB+'),('AB-'),('O+'),('O-')) ORDER BY RANDOM() LIMIT 1),
    insurance_provider = (SELECT ins FROM (SELECT column1 AS ins FROM VALUES ('Blue Cross'),('Aetna'),('UnitedHealth'),('Cigna'),('Humana'),('Kaiser'),('Medicare'),('Medicaid')) ORDER BY RANDOM() LIMIT 1),
    primary_physician = (SELECT doc FROM (SELECT column1 AS doc FROM VALUES ('Dr. Sarah Chen'),('Dr. Michael Roberts'),('Dr. Emily Watson'),('Dr. James Park'),('Dr. Lisa Thompson'),('Dr. Robert Kim'),('Dr. Amanda Garcia'),('Dr. David Lee')) ORDER BY RANDOM() LIMIT 1);

-- Load procedures (2000 records)
INSERT INTO SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures
WITH procedure_types AS (
    SELECT column1 AS proc_type, column2 AS dept, column3 AS base_cost, column4 AS base_duration FROM VALUES
    ('Annual Physical','Primary Care',150,30),
    ('Blood Test','Laboratory',75,15),
    ('X-Ray','Radiology',250,20),
    ('MRI Scan','Radiology',1200,45),
    ('CT Scan','Radiology',800,30),
    ('Ultrasound','Radiology',350,25),
    ('ECG','Cardiology',200,20),
    ('Echocardiogram','Cardiology',500,40),
    ('Colonoscopy','Gastroenterology',1500,60),
    ('Endoscopy','Gastroenterology',1200,45),
    ('Minor Surgery','Surgery',2500,90),
    ('Joint Injection','Orthopedics',400,20),
    ('Physical Therapy','Rehabilitation',150,45),
    ('Vaccination','Primary Care',50,10),
    ('Skin Biopsy','Dermatology',600,30),
    ('Eye Exam','Ophthalmology',175,25),
    ('Hearing Test','ENT',125,20),
    ('Allergy Test','Immunology',300,30),
    ('Stress Test','Cardiology',750,45),
    ('Mammogram','Radiology',300,20)
),
physicians AS (
    SELECT column1 AS doc FROM VALUES
    ('Dr. Sarah Chen'),('Dr. Michael Roberts'),('Dr. Emily Watson'),('Dr. James Park'),
    ('Dr. Lisa Thompson'),('Dr. Robert Kim'),('Dr. Amanda Garcia'),('Dr. David Lee')
)
SELECT
    ROW_NUMBER() OVER (ORDER BY RANDOM()) AS procedure_id,
    p.patient_id,
    DATEADD('day', -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()) AS procedure_date,
    pt.proc_type AS procedure_type,
    pt.dept AS department,
    (SELECT doc FROM physicians ORDER BY RANDOM() LIMIT 1) AS physician,
    pt.base_duration + UNIFORM(-5, 15, RANDOM()) AS duration_minutes,
    pt.base_cost * (1 + (UNIFORM(-20, 30, RANDOM()) / 100.0)) AS cost_usd,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Scheduled'
        WHEN 2 THEN 'In Progress'
        ELSE 'Completed'
    END AS status
FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients p
CROSS JOIN procedure_types pt
WHERE RANDOM() < 0.15
ORDER BY RANDOM()
LIMIT 2000;

-- Load diagnoses (1500 records)
INSERT INTO SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.diagnoses
WITH diagnosis_list AS (
    SELECT column1 AS icd, column2 AS name, column3 AS sev FROM VALUES
    ('J06.9','Upper Respiratory Infection','Mild'),
    ('I10','Essential Hypertension','Moderate'),
    ('E11.9','Type 2 Diabetes','Moderate'),
    ('M54.5','Low Back Pain','Mild'),
    ('J45.909','Asthma','Moderate'),
    ('F41.1','Generalized Anxiety Disorder','Moderate'),
    ('K21.0','GERD','Mild'),
    ('M79.3','Panniculitis','Mild'),
    ('E78.5','Hyperlipidemia','Moderate'),
    ('G43.909','Migraine','Moderate'),
    ('J02.9','Acute Pharyngitis','Mild'),
    ('N39.0','Urinary Tract Infection','Mild'),
    ('L30.9','Dermatitis','Mild'),
    ('H10.9','Conjunctivitis','Mild'),
    ('R51','Headache','Mild'),
    ('K59.00','Constipation','Mild'),
    ('R10.9','Abdominal Pain','Moderate'),
    ('M25.50','Joint Pain','Moderate'),
    ('F32.9','Major Depressive Disorder','Severe'),
    ('I25.10','Coronary Artery Disease','Severe')
),
physicians AS (
    SELECT column1 AS doc FROM VALUES
    ('Dr. Sarah Chen'),('Dr. Michael Roberts'),('Dr. Emily Watson'),('Dr. James Park'),
    ('Dr. Lisa Thompson'),('Dr. Robert Kim'),('Dr. Amanda Garcia'),('Dr. David Lee')
)
SELECT
    ROW_NUMBER() OVER (ORDER BY RANDOM()) AS diagnosis_id,
    p.patient_id,
    DATEADD('day', -UNIFORM(1, 730, RANDOM()), CURRENT_DATE()) AS diagnosis_date,
    d.icd AS icd_code,
    d.name AS diagnosis_name,
    d.sev AS severity,
    (SELECT doc FROM physicians ORDER BY RANDOM() LIMIT 1) AS treating_physician
FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients p
CROSS JOIN diagnosis_list d
WHERE RANDOM() < 0.08
ORDER BY RANDOM()
LIMIT 1500;

-- Verification
SELECT
    (SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients) AS patients,
    (SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures) AS procedures,
    (SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.diagnoses) AS diagnoses;
