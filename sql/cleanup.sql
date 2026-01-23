/*******************************************************************************
 * CLEANUP SCRIPT - Cortex Agent Slack Integration
 * AUTHOR: SE Community
 * EXPIRES: 2026-02-22
 *
 * Run this script to remove all demo objects.
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

-- Remove project-specific objects
DROP WAREHOUSE IF EXISTS SFE_CORTEX_AGENT_SLACK_WH;
DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK CASCADE;
DROP ROLE IF EXISTS cortex_agent_slack_role;

-- Remove Git repository (optional - may be shared)
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO;

-- PROTECTED (do not drop - shared infrastructure):
-- - SNOWFLAKE_EXAMPLE database
-- - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema
-- - SNOWFLAKE_EXAMPLE.GIT_REPOS schema
-- - SFE_GIT_API_INTEGRATION (shared across demos)

SELECT 'Cleanup Complete!' AS status;
