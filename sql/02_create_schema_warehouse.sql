/*******************************************************************************
 * Step 2: Infrastructure Creation (SYSADMIN)
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 *
 * SYSADMIN owns all infrastructure: database, schemas, warehouse.
 * Grants USAGE and CREATE privileges to the app role.
 ******************************************************************************/

USE ROLE SYSADMIN;

-- Create shared demo database (SYSADMIN owns)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Shared demo database for SE examples';

-- Create project schema (SYSADMIN owns)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

-- Create shared semantic models schema (SYSADMIN owns)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
    COMMENT = 'DEMO: Shared semantic views for Cortex Analyst agents';

-- Create warehouse (SYSADMIN owns)
CREATE WAREHOUSE IF NOT EXISTS SFE_CORTEX_AGENT_SLACK_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

-- Grant privileges to app role
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE cortex_agent_slack_role;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE cortex_agent_slack_role;
GRANT USAGE ON WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH TO ROLE cortex_agent_slack_role;

-- Grant CREATE privileges for app objects
GRANT CREATE TABLE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;
GRANT CREATE VIEW ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;
GRANT CREATE PROCEDURE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;
GRANT CREATE SEMANTIC VIEW ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE cortex_agent_slack_role;
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;
GRANT CREATE AUTHENTICATION POLICY ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;

-- Set context for subsequent scripts (switch to app role)
USE ROLE cortex_agent_slack_role;
USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;
