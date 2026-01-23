/*******************************************************************************
 * Step 1: Role and Permissions Setup
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

-- Create project role with proper hierarchy
CREATE ROLE IF NOT EXISTS cortex_agent_slack_role
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';
GRANT ROLE cortex_agent_slack_role TO ROLE SYSADMIN;

-- Grant account-level privileges
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE cortex_agent_slack_role;

-- Grant Cortex database roles (both required for agent creation and usage)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE cortex_agent_slack_role;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE cortex_agent_slack_role;

-- Grant privileges on shared demo database
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE cortex_agent_slack_role;
GRANT CREATE SCHEMA ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE cortex_agent_slack_role;

-- Assign role to current user
SET current_user = (SELECT CURRENT_USER());
GRANT ROLE cortex_agent_slack_role TO USER IDENTIFIER($current_user);

SELECT 'Role and permissions configured' AS status;
