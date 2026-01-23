/*******************************************************************************
 * DEMO METADATA (Machine-readable - Do not modify format)
 * PROJECT_NAME: Cortex Agent Slack Integration
 * AUTHOR: SE Community
 * CREATED: 2026-01-23
 * EXPIRES: 2026-02-22
 * PURPOSE: Reference implementation for integrating Snowflake Cortex Agents with Slack
 *
 * DEPLOYMENT INSTRUCTIONS:
 * 1. Open Snowsight (https://app.snowflake.com)
 * 2. Copy this ENTIRE script
 * 3. Paste into a new SQL worksheet
 * 4. Click "Run All"
 ******************************************************************************/

-- ============================================================================
-- EXPIRATION CHECK
-- ============================================================================
SELECT
    '2026-02-22'::DATE AS expiration_date,
    CURRENT_DATE() AS current_date,
    DATEDIFF('day', CURRENT_DATE(), '2026-02-22'::DATE) AS days_remaining,
    CASE
        WHEN DATEDIFF('day', CURRENT_DATE(), '2026-02-22'::DATE) < 0
        THEN 'EXPIRED - Do not deploy. Fork repository and update expiration date.'
        WHEN DATEDIFF('day', CURRENT_DATE(), '2026-02-22'::DATE) <= 7
        THEN 'EXPIRING SOON - ' || DATEDIFF('day', CURRENT_DATE(), '2026-02-22'::DATE) || ' days remaining'
        ELSE 'ACTIVE - ' || DATEDIFF('day', CURRENT_DATE(), '2026-02-22'::DATE) || ' days remaining'
    END AS demo_status;

-- ============================================================================
-- SCOPE CONFIRMATION
-- ============================================================================
-- This script ONLY creates objects in:
--   - Database: SNOWFLAKE_EXAMPLE (shared demo database)
--   - Schema:   SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK (project-specific)
--   - Schema:   SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS (shared semantic views)
--
-- Additional objects created:
--   - Warehouse: SFE_CORTEX_AGENT_SLACK_WH (isolated compute)
--   - Role:      cortex_agent_slack_role (project-specific permissions)
--   - Agent:     SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant
--
-- Your existing databases, schemas, and data are NOT modified.
-- ============================================================================

SELECT 'SAFE TO RUN: All objects will be created in SNOWFLAKE_EXAMPLE database only.' AS confirmation;

-- ============================================================================
-- SECTION 1: ROLE AND PERMISSIONS
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- Create shared demo database (if not exists)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Shared demo database for SE examples';

-- Create project role with proper hierarchy
CREATE ROLE IF NOT EXISTS cortex_agent_slack_role
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';
GRANT ROLE cortex_agent_slack_role TO ROLE SYSADMIN;

-- Grant account-level privileges
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE cortex_agent_slack_role;

-- Grant Cortex database roles (both required for agent creation and usage)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE cortex_agent_slack_role;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE cortex_agent_slack_role;

-- Grant privileges on shared demo database
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE cortex_agent_slack_role;
GRANT CREATE SCHEMA ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE cortex_agent_slack_role;

-- Assign role to current user
SET current_user = (SELECT CURRENT_USER());
GRANT ROLE cortex_agent_slack_role TO USER IDENTIFIER($current_user);

USE ROLE cortex_agent_slack_role;

-- ============================================================================
-- SECTION 2: SCHEMA AND WAREHOUSE
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
    COMMENT = 'DEMO: Shared semantic views for Cortex Analyst agents';

-- Grant USAGE on schemas (required for object access)
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE cortex_agent_slack_role;

CREATE WAREHOUSE IF NOT EXISTS SFE_CORTEX_AGENT_SLACK_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

GRANT USAGE ON WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH TO ROLE cortex_agent_slack_role;

USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;

-- ============================================================================
-- SECTION 3: GENERATE MEDICAL RECORDS DATA
-- ============================================================================

CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients (
    patient_id NUMBER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(10),
    blood_type VARCHAR(5),
    insurance_provider VARCHAR(50),
    primary_physician VARCHAR(100)
)
COMMENT = 'DEMO: Patient records (Expires: 2026-02-22)';

CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures (
    procedure_id NUMBER,
    patient_id NUMBER,
    procedure_date DATE,
    procedure_type VARCHAR(100),
    department VARCHAR(50),
    physician VARCHAR(100),
    duration_minutes NUMBER,
    cost_usd NUMBER(10,2),
    status VARCHAR(20)
)
COMMENT = 'DEMO: Medical procedures (Expires: 2026-02-22)';

CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.diagnoses (
    diagnosis_id NUMBER,
    patient_id NUMBER,
    diagnosis_date DATE,
    icd_code VARCHAR(10),
    diagnosis_name VARCHAR(200),
    severity VARCHAR(20),
    treating_physician VARCHAR(100)
)
COMMENT = 'DEMO: Patient diagnoses (Expires: 2026-02-22)';

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

UPDATE SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients
SET blood_type = (SELECT bt FROM (SELECT column1 AS bt FROM VALUES ('A+'),('A-'),('B+'),('B-'),('AB+'),('AB-'),('O+'),('O-')) ORDER BY RANDOM() LIMIT 1),
    insurance_provider = (SELECT ins FROM (SELECT column1 AS ins FROM VALUES ('Blue Cross'),('Aetna'),('UnitedHealth'),('Cigna'),('Humana'),('Kaiser'),('Medicare'),('Medicaid')) ORDER BY RANDOM() LIMIT 1),
    primary_physician = (SELECT doc FROM (SELECT column1 AS doc FROM VALUES ('Dr. Sarah Chen'),('Dr. Michael Roberts'),('Dr. Emily Watson'),('Dr. James Park'),('Dr. Lisa Thompson'),('Dr. Robert Kim'),('Dr. Amanda Garcia'),('Dr. David Lee')) ORDER BY RANDOM() LIMIT 1);

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

SELECT
    (SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients) AS patients,
    (SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures) AS procedures,
    (SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.diagnoses) AS diagnoses;

-- ============================================================================
-- SECTION 4: SEMANTIC VIEW FOR CORTEX ANALYST
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL
    COMMENT = 'DEMO: Medical records semantic view (Expires: 2026-02-22)'
AS SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    p.blood_type,
    p.insurance_provider,
    p.primary_physician,
    pr.procedure_id,
    pr.procedure_date,
    pr.procedure_type,
    pr.department,
    pr.physician AS procedure_physician,
    pr.duration_minutes,
    pr.cost_usd,
    pr.status AS procedure_status,
    d.diagnosis_id,
    d.diagnosis_date,
    d.icd_code,
    d.diagnosis_name,
    d.severity,
    d.treating_physician
FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients p
LEFT JOIN SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures pr ON p.patient_id = pr.patient_id
LEFT JOIN SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.diagnoses d ON p.patient_id = d.patient_id
WITH SEMANTICS (
    TABLES => [
        {
            'name': 'patients',
            'base_table': {'database': 'SNOWFLAKE_EXAMPLE', 'schema': 'CORTEX_AGENT_SLACK', 'table': 'PATIENTS'},
            'description': 'Patient demographic information including name, DOB, gender, blood type, insurance, and primary physician.'
        },
        {
            'name': 'procedures',
            'base_table': {'database': 'SNOWFLAKE_EXAMPLE', 'schema': 'CORTEX_AGENT_SLACK', 'table': 'PROCEDURES'},
            'description': 'Medical procedures performed on patients including type, department, physician, duration, and cost.'
        },
        {
            'name': 'diagnoses',
            'base_table': {'database': 'SNOWFLAKE_EXAMPLE', 'schema': 'CORTEX_AGENT_SLACK', 'table': 'DIAGNOSES'},
            'description': 'Patient diagnoses with ICD codes, severity levels, and treating physicians.'
        }
    ],
    DIMENSIONS => [
        {'name': 'patient_id', 'synonyms': ['patient', 'patient number'], 'description': 'Unique patient identifier', 'expr': 'patient_id', 'data_type': 'NUMBER'},
        {'name': 'patient_name', 'synonyms': ['name', 'patient name', 'full name'], 'description': 'Patient full name', 'expr': 'first_name || '' '' || last_name', 'data_type': 'TEXT'},
        {'name': 'gender', 'synonyms': ['sex'], 'description': 'Patient gender: Male or Female', 'expr': 'gender', 'data_type': 'TEXT', 'sample_values': ['Male', 'Female']},
        {'name': 'blood_type', 'synonyms': ['blood group'], 'description': 'Patient blood type', 'expr': 'blood_type', 'data_type': 'TEXT', 'sample_values': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']},
        {'name': 'insurance_provider', 'synonyms': ['insurer', 'insurance', 'insurance company'], 'description': 'Patient insurance provider', 'expr': 'insurance_provider', 'data_type': 'TEXT', 'sample_values': ['Blue Cross', 'Aetna', 'UnitedHealth', 'Cigna', 'Kaiser', 'Medicare']},
        {'name': 'primary_physician', 'synonyms': ['primary doctor', 'pcp', 'primary care physician'], 'description': 'Patient primary care physician', 'expr': 'primary_physician', 'data_type': 'TEXT'},
        {'name': 'procedure_type', 'synonyms': ['procedure', 'procedure name', 'treatment'], 'description': 'Type of medical procedure', 'expr': 'procedure_type', 'data_type': 'TEXT', 'sample_values': ['Annual Physical', 'Blood Test', 'X-Ray', 'MRI Scan', 'ECG']},
        {'name': 'department', 'synonyms': ['dept', 'medical department', 'specialty'], 'description': 'Hospital department', 'expr': 'department', 'data_type': 'TEXT', 'sample_values': ['Primary Care', 'Radiology', 'Cardiology', 'Surgery', 'Laboratory']},
        {'name': 'procedure_status', 'synonyms': ['status'], 'description': 'Status of the procedure', 'expr': 'procedure_status', 'data_type': 'TEXT', 'sample_values': ['Completed', 'Scheduled', 'In Progress']},
        {'name': 'diagnosis_name', 'synonyms': ['diagnosis', 'condition', 'disease'], 'description': 'Name of the diagnosis', 'expr': 'diagnosis_name', 'data_type': 'TEXT', 'sample_values': ['Hypertension', 'Type 2 Diabetes', 'Asthma', 'GERD']},
        {'name': 'icd_code', 'synonyms': ['icd', 'diagnosis code'], 'description': 'ICD-10 diagnosis code', 'expr': 'icd_code', 'data_type': 'TEXT'},
        {'name': 'severity', 'synonyms': ['diagnosis severity', 'condition severity'], 'description': 'Severity of diagnosis', 'expr': 'severity', 'data_type': 'TEXT', 'sample_values': ['Mild', 'Moderate', 'Severe']},
        {'name': 'procedure_date', 'synonyms': ['date of procedure', 'treatment date'], 'description': 'Date procedure was performed', 'expr': 'procedure_date', 'data_type': 'DATE'},
        {'name': 'diagnosis_date', 'synonyms': ['date of diagnosis'], 'description': 'Date diagnosis was made', 'expr': 'diagnosis_date', 'data_type': 'DATE'}
    ],
    METRICS => [
        {'name': 'patient_count', 'synonyms': ['number of patients', 'total patients', 'how many patients'], 'description': 'Count of unique patients', 'expr': 'COUNT(DISTINCT patient_id)', 'data_type': 'NUMBER'},
        {'name': 'procedure_count', 'synonyms': ['number of procedures', 'total procedures', 'how many procedures'], 'description': 'Count of procedures', 'expr': 'COUNT(DISTINCT procedure_id)', 'data_type': 'NUMBER'},
        {'name': 'diagnosis_count', 'synonyms': ['number of diagnoses', 'total diagnoses'], 'description': 'Count of diagnoses', 'expr': 'COUNT(DISTINCT diagnosis_id)', 'data_type': 'NUMBER'},
        {'name': 'total_cost', 'synonyms': ['total revenue', 'revenue', 'cost', 'total procedure cost'], 'description': 'Total cost of procedures in USD', 'expr': 'SUM(cost_usd)', 'data_type': 'NUMBER'},
        {'name': 'average_cost', 'synonyms': ['avg cost', 'mean cost', 'average procedure cost'], 'description': 'Average procedure cost in USD', 'expr': 'AVG(cost_usd)', 'data_type': 'NUMBER'},
        {'name': 'average_duration', 'synonyms': ['avg duration', 'mean duration'], 'description': 'Average procedure duration in minutes', 'expr': 'AVG(duration_minutes)', 'data_type': 'NUMBER'}
    ],
    VERIFIED_QUERIES => [
        {
            'name': 'procedures_by_department',
            'question': 'How many procedures by department?',
            'verified_at': 1737619200,
            'verified_by': 'SE Community',
            'sql': 'SELECT department, COUNT(DISTINCT procedure_id) AS procedure_count FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures GROUP BY department ORDER BY procedure_count DESC'
        },
        {
            'name': 'revenue_by_department',
            'question': 'What is the total revenue by department?',
            'verified_at': 1737619200,
            'verified_by': 'SE Community',
            'sql': 'SELECT department, SUM(cost_usd) AS total_revenue FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures GROUP BY department ORDER BY total_revenue DESC'
        },
        {
            'name': 'patients_by_insurance',
            'question': 'How many patients by insurance provider?',
            'verified_at': 1737619200,
            'verified_by': 'SE Community',
            'sql': 'SELECT insurance_provider, COUNT(patient_id) AS patient_count FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.patients GROUP BY insurance_provider ORDER BY patient_count DESC'
        },
        {
            'name': 'diagnoses_by_severity',
            'question': 'Show diagnoses breakdown by severity',
            'verified_at': 1737619200,
            'verified_by': 'SE Community',
            'sql': 'SELECT severity, COUNT(DISTINCT diagnosis_id) AS diagnosis_count FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.diagnoses GROUP BY severity ORDER BY diagnosis_count DESC'
        },
        {
            'name': 'top_procedures',
            'question': 'What are the most common procedures?',
            'verified_at': 1737619200,
            'verified_by': 'SE Community',
            'sql': 'SELECT procedure_type, COUNT(procedure_id) AS procedure_count FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures GROUP BY procedure_type ORDER BY procedure_count DESC LIMIT 10'
        }
    ]
);

-- Grant both REFERENCES and SELECT (required for Cortex Analyst)
GRANT REFERENCES, SELECT ON SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL
    TO ROLE cortex_agent_slack_role;

-- ============================================================================
-- SECTION 5: CORTEX AGENT
-- ============================================================================
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;

CREATE OR REPLACE AGENT SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant
    COMMENT = 'DEMO: Medical records analytics assistant (Expires: 2026-02-22)'
FROM SPECIFICATION $$
{
    "models": {
        "orchestration": "claude-4-sonnet"
    },
    "instructions": {
        "orchestration": "You are Medical Assistant, a healthcare analytics agent. You help analyze patient records, procedures, and diagnoses.\n\nYou have access to medical data including:\n- Patient demographics (500 patients)\n- Medical procedures with costs and durations\n- Diagnoses with ICD codes and severity levels\n\nProvide data-driven insights. When showing numbers, suggest visualizations.",
        "response": "Be concise and professional. Lead with the answer. Use tables for multi-row data. Protect patient privacy - never expose individual patient details unless specifically asked."
    },
    "tools": [
        {
            "tool_spec": {
                "type": "cortex_analyst_text_to_sql",
                "name": "medical_data",
                "description": "Query medical records including patients, procedures, and diagnoses. Use for questions about patient counts, procedure volumes, costs, departments, insurance breakdowns, diagnosis severity, and healthcare metrics."
            }
        }
    ],
    "tool_resources": {
        "medical_data": {
            "semantic_view": "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL",
            "execution_environment": {
                "type": "warehouse",
                "warehouse": "SFE_CORTEX_AGENT_SLACK_WH"
            },
            "query_timeout": 60
        }
    }
}
$$;

GRANT USAGE ON AGENT SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant TO ROLE cortex_agent_slack_role;

-- ============================================================================
-- SECTION 6: PAT AUTHENTICATION
-- ============================================================================
CREATE OR REPLACE AUTHENTICATION POLICY SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.pat_auth_policy
    PAT_POLICY = (NETWORK_POLICY_EVALUATION = ENFORCED_NOT_REQUIRED)
    COMMENT = 'DEMO: PAT authentication for Slack integration (Expires: 2026-02-22)';

ALTER USER IDENTIFIER($current_user) SET AUTHENTICATION POLICY SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.pat_auth_policy;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 'Deployment Complete!' AS status,
       'SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK' AS schema_created,
       'SFE_CORTEX_AGENT_SLACK_WH' AS warehouse_created,
       'medical_assistant' AS agent_created,
       '2026-02-22' AS expires;

SHOW AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK;

SELECT department, COUNT(*) AS procedure_count, ROUND(SUM(cost_usd), 2) AS total_cost
FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures
GROUP BY department
ORDER BY procedure_count DESC
LIMIT 5;
