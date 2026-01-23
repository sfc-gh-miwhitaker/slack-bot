/*******************************************************************************
 * Step 3: Table Creation
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE cortex_agent_slack_role;
USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;

-- Patients table
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

-- Procedures table
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

-- Diagnoses table
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
