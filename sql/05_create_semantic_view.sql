/*******************************************************************************
 * Step 5: Create Semantic View for Cortex Analyst
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE cortex_agent_slack_role;
USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL

  TABLES (
    patients AS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.PATIENTS
      PRIMARY KEY (patient_id)
      COMMENT = 'Patient demographic information including name, DOB, gender, blood type, insurance, and primary physician.',

    procedures AS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.PROCEDURES
      PRIMARY KEY (procedure_id)
      COMMENT = 'Medical procedures performed on patients including type, department, physician, duration, and cost.',

    diagnoses AS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.DIAGNOSES
      PRIMARY KEY (diagnosis_id)
      COMMENT = 'Patient diagnoses with ICD codes, severity levels, and treating physicians.'
  )

  RELATIONSHIPS (
    procedures (patient_id) REFERENCES patients,
    diagnoses (patient_id) REFERENCES patients
  )

  DIMENSIONS (
    -- Patient dimensions
    patients.patient_id AS patient_id
      WITH SYNONYMS = ('patient', 'patient number')
      COMMENT = 'Unique patient identifier',

    patients.patient_name AS first_name || ' ' || last_name
      WITH SYNONYMS = ('name', 'patient name', 'full name')
      COMMENT = 'Patient full name',

    patients.gender AS gender
      WITH SYNONYMS = ('sex')
      COMMENT = 'Patient gender: Male or Female',

    patients.blood_type AS blood_type
      WITH SYNONYMS = ('blood group')
      COMMENT = 'Patient blood type',

    patients.insurance_provider AS insurance_provider
      WITH SYNONYMS = ('insurer', 'insurance', 'insurance company')
      COMMENT = 'Patient insurance provider',

    patients.primary_physician AS primary_physician
      WITH SYNONYMS = ('primary doctor', 'pcp', 'primary care physician')
      COMMENT = 'Patient primary care physician',

    -- Procedure dimensions
    procedures.procedure_type AS procedure_type
      WITH SYNONYMS = ('procedure', 'procedure name', 'treatment')
      COMMENT = 'Type of medical procedure',

    procedures.department AS department
      WITH SYNONYMS = ('dept', 'medical department', 'specialty')
      COMMENT = 'Hospital department',

    procedures.status AS status
      WITH SYNONYMS = ('procedure status')
      COMMENT = 'Status of the procedure',

    procedures.procedure_date AS procedure_date
      WITH SYNONYMS = ('date of procedure', 'treatment date')
      COMMENT = 'Date procedure was performed',

    -- Diagnosis dimensions
    diagnoses.diagnosis_name AS diagnosis_name
      WITH SYNONYMS = ('diagnosis', 'condition', 'disease')
      COMMENT = 'Name of the diagnosis',

    diagnoses.icd_code AS icd_code
      WITH SYNONYMS = ('icd', 'diagnosis code')
      COMMENT = 'ICD-10 diagnosis code',

    diagnoses.severity AS severity
      WITH SYNONYMS = ('diagnosis severity', 'condition severity')
      COMMENT = 'Severity of diagnosis',

    diagnoses.diagnosis_date AS diagnosis_date
      WITH SYNONYMS = ('date of diagnosis')
      COMMENT = 'Date diagnosis was made'
  )

  METRICS (
    patients.patient_count AS COUNT(DISTINCT patient_id)
      WITH SYNONYMS = ('number of patients', 'total patients', 'how many patients')
      COMMENT = 'Count of unique patients',

    procedures.procedure_count AS COUNT(DISTINCT procedure_id)
      WITH SYNONYMS = ('number of procedures', 'total procedures', 'how many procedures')
      COMMENT = 'Count of procedures',

    diagnoses.diagnosis_count AS COUNT(DISTINCT diagnosis_id)
      WITH SYNONYMS = ('number of diagnoses', 'total diagnoses')
      COMMENT = 'Count of diagnoses',

    procedures.total_cost AS SUM(cost_usd)
      WITH SYNONYMS = ('total revenue', 'revenue', 'cost', 'total procedure cost')
      COMMENT = 'Total cost of procedures in USD',

    procedures.average_cost AS AVG(cost_usd)
      WITH SYNONYMS = ('avg cost', 'mean cost', 'average procedure cost')
      COMMENT = 'Average procedure cost in USD',

    procedures.average_duration AS AVG(duration_minutes)
      WITH SYNONYMS = ('avg duration', 'mean duration')
      COMMENT = 'Average procedure duration in minutes'
  )

  COMMENT = 'DEMO: Medical records semantic view (Expires: 2026-02-22)'
;

-- Grant both REFERENCES and SELECT (required for Cortex Analyst)
GRANT REFERENCES, SELECT ON SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL
    TO ROLE cortex_agent_slack_role;
