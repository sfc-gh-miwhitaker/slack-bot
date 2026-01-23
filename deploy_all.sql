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
-- This script creates objects in:
--   - Database: SNOWFLAKE_EXAMPLE (shared demo database)
--   - Schema:   SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK (project-specific)
--   - Schema:   SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS (shared semantic views)
--   - Warehouse: SFE_CORTEX_AGENT_SLACK_WH (isolated compute)
--   - Role:      cortex_agent_slack_role (project-specific permissions)
--   - Agent:     SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.medical_assistant
--
-- Your existing databases, schemas, and data are NOT modified.
-- ============================================================================

SELECT 'SAFE TO RUN: All objects will be created in SNOWFLAKE_EXAMPLE database only.' AS confirmation;

-- ============================================================================
-- SECTION 1: GIT REPOSITORY INTEGRATION
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- Create shared demo database and Git infrastructure
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Shared demo database for SE examples';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
    COMMENT = 'DEMO: Shared Git repository integrations';

-- Create API integration for GitHub (reusable across demos)
CREATE API INTEGRATION IF NOT EXISTS SFE_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
    ENABLED = TRUE
    COMMENT = 'DEMO: GitHub API integration for SE demos';

-- Create Git repository for this demo
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO
    API_INTEGRATION = SFE_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/slack-bot.git'
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

-- Fetch latest from repository
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO FETCH;

-- List available files
SELECT 'Repository files:' AS info;
LS @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/;

-- ============================================================================
-- SECTION 2: EXECUTE DEPLOYMENT SCRIPTS FROM GIT
-- ============================================================================
SELECT 'Step 1: Setting up role and permissions...' AS status;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/01_setup_role_permissions.sql;

SELECT 'Step 2: Creating schemas and warehouse...' AS status;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/02_create_schema_warehouse.sql;

SELECT 'Step 3: Creating tables...' AS status;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/03_create_tables.sql;

SELECT 'Step 4: Loading sample data...' AS status;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/04_load_data.sql;

SELECT 'Step 5: Creating semantic view...' AS status;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/05_create_semantic_view.sql;

SELECT 'Step 6: Creating Cortex Agent...' AS status;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/06_create_agent.sql;

SELECT 'Step 7: Setting up PAT authentication...' AS status;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.CORTEX_AGENT_SLACK_REPO/branches/main/sql/07_setup_authentication.sql;

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
