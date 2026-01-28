/*******************************************************************************
 * Step 1: Role Setup (ACCOUNTADMIN)
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 *
 * ACCOUNTADMIN only creates role and grants account-level privileges.
 * Infrastructure is owned by SYSADMIN.
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

-- Create project role with proper hierarchy (reports to SYSADMIN)
CREATE ROLE IF NOT EXISTS cortex_agent_slack_role
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';
GRANT ROLE cortex_agent_slack_role TO ROLE SYSADMIN;

-- Grant Cortex database roles (required for agent creation and usage)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE cortex_agent_slack_role;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE cortex_agent_slack_role;

-- NOTE: Role grant to current user is in deploy_all.sql
-- (session variables not supported in EXECUTE IMMEDIATE FROM)
