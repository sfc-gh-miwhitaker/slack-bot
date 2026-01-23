/*******************************************************************************
 * CLEANUP SCRIPT - Cortex Agent Slack Integration
 * AUTHOR: SE Community
 * EXPIRES: 2026-02-22
 *
 * Run this script to remove all demo objects.
 * Uses ACCOUNTADMIN first (to unset policies), then SYSADMIN for infrastructure.
 ******************************************************************************/

-- ============================================================================
-- ACCOUNTADMIN: Unset authentication policy from user (required before drop)
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- Must unset policy before dropping schema that contains it
SET current_user = (SELECT CURRENT_USER());
ALTER USER IDENTIFIER($current_user) UNSET AUTHENTICATION POLICY;

-- ============================================================================
-- SYSADMIN: Remove infrastructure it owns
-- ============================================================================
USE ROLE SYSADMIN;

-- Remove warehouse (owned by SYSADMIN)
DROP WAREHOUSE IF EXISTS SFE_CORTEX_AGENT_SLACK_WH;

-- Remove application objects (owned by app role, but SYSADMIN can drop)
DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CORTEX_AGENT_SLACK_MEDICAL;

-- Remove project schema with cascade (owned by SYSADMIN)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK CASCADE;

-- Remove Git repository (owned by SYSADMIN)
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO;

-- ============================================================================
-- ACCOUNTADMIN: Remove role it created
-- ============================================================================
USE ROLE ACCOUNTADMIN;

DROP ROLE IF EXISTS cortex_agent_slack_role;

-- ============================================================================
-- PROTECTED (do not drop - shared infrastructure):
-- ============================================================================
-- - SNOWFLAKE_EXAMPLE database
-- - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema
-- - SNOWFLAKE_EXAMPLE.GIT_REPOS schema
-- - SFE_GIT_API_INTEGRATION (shared across demos)
