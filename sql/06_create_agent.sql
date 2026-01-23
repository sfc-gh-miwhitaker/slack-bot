/*******************************************************************************
 * Step 6: Create Cortex Agent
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE cortex_agent_slack_role;
USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;

-- Grant CREATE AGENT privilege
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;

-- Create the Cortex Agent
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

-- Grant USAGE on the agent
GRANT USAGE ON AGENT SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant TO ROLE cortex_agent_slack_role;

SELECT 'Cortex Agent created' AS status;
