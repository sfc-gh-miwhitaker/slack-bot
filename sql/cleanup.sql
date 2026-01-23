/*******************************************************************************
 * CLEANUP SCRIPT - Cortex Agent Slack Integration
 * AUTHOR: SE Community
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

DROP WAREHOUSE IF EXISTS SFE_CORTEX_AGENT_SLACK_WH;
DROP AGENT IF EXISTS snowflake_intelligence.agents.medical_assistant;
DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK CASCADE;
DROP ROLE IF EXISTS cortex_agent_slack_role;

-- PROTECTED (do not drop):
-- - SNOWFLAKE_EXAMPLE database
-- - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema
-- - snowflake_intelligence database/schema

SELECT 'Cleanup Complete!' AS status;
