/*******************************************************************************
 * DEMO METADATA (Machine-readable - Do not modify format)
 * PROJECT_NAME: Cortex Agent Slack Integration
 * AUTHOR: SE Community
 * CREATED: 2026-01-23
 * EXPIRES: 2026-02-22
 * PURPOSE: Reference implementation for integrating Snowflake Cortex Agents with Slack
 *
 * OWNERSHIP:
 *   - ACCOUNTADMIN: Creates role and API integration only
 *   - SYSADMIN: Owns all infrastructure (database, schemas, warehouse, git repo)
 *   - cortex_agent_slack_role: Owns application objects (tables, views, agents)
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
-- This script creates objects in:
--   - Database: SNOWFLAKE_EXAMPLE (shared demo database, owned by SYSADMIN)
--   - Schema:   SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK (owned by SYSADMIN)
--   - Schema:   SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS (owned by SYSADMIN)
--   - Warehouse: SFE_CORTEX_AGENT_SLACK_WH (owned by SYSADMIN)
--   - Role:      cortex_agent_slack_role (app role for runtime)
--   - Agent:     SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant
--
-- Your existing databases, schemas, and data are NOT modified.
-- ============================================================================

-- ============================================================================
-- SECTION 1: ACCOUNTADMIN - API INTEGRATION ONLY
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- API integrations require ACCOUNTADMIN
CREATE API INTEGRATION IF NOT EXISTS SFE_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
    ENABLED = TRUE
    COMMENT = 'DEMO: GitHub API integration for SE demos';

-- Grant integration usage to SYSADMIN
GRANT USAGE ON INTEGRATION SFE_GIT_API_INTEGRATION TO ROLE SYSADMIN;

-- ============================================================================
-- SECTION 2: SYSADMIN - GIT REPOSITORY INFRASTRUCTURE
-- ============================================================================
USE ROLE SYSADMIN;

-- Create shared demo database (SYSADMIN owns)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Shared demo database for SE examples';

-- Create Git infrastructure schema (SYSADMIN owns)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
    COMMENT = 'DEMO: Shared Git repository integrations';

-- Create Git repository for this demo (SYSADMIN owns)
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO
    API_INTEGRATION = SFE_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/slack-bot.git'
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

-- Fetch latest from repository
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO FETCH;

-- Verify repository contents
LS @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/;

-- ============================================================================
-- SECTION 3: EXECUTE DEPLOYMENT SCRIPTS FROM GIT
-- ============================================================================
-- Step 1: Role setup (ACCOUNTADMIN)
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/01_setup_role_permissions.sql;

-- Step 2: Infrastructure (SYSADMIN creates, grants to app role)
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/02_create_schema_warehouse.sql;

-- Step 3-7: Application objects (app role owns)
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/03_create_tables.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/04_load_data.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/05_create_semantic_view.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/06_create_agent.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/07_setup_authentication.sql;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SHOW AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK;

-- Sample query to verify data
SELECT department, COUNT(*) AS procedure_count, ROUND(SUM(cost_usd), 2) AS total_cost
FROM SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.procedures
GROUP BY department
ORDER BY procedure_count DESC
LIMIT 5;
