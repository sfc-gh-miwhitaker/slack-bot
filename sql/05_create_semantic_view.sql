/*******************************************************************************
 * Step 5: Create Semantic View for Cortex Analyst
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE cortex_agent_slack_role;
USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;

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

SELECT 'Semantic view created' AS status;
