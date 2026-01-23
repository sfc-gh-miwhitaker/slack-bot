/*******************************************************************************
 * Step 2: Schema and Warehouse Creation
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE cortex_agent_slack_role;

-- Create project schema
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

-- Create shared semantic models schema
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
    COMMENT = 'DEMO: Shared semantic views for Cortex Analyst agents';

-- Grant USAGE on schemas (required for object access)
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK TO ROLE cortex_agent_slack_role;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE cortex_agent_slack_role;

-- Grant CREATE SEMANTIC VIEW on semantic models schema
GRANT CREATE SEMANTIC VIEW ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE cortex_agent_slack_role;

-- Create warehouse with cost-optimized settings
CREATE WAREHOUSE IF NOT EXISTS SFE_CORTEX_AGENT_SLACK_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: Cortex Agent Slack Integration (Expires: 2026-02-22)';

GRANT USAGE ON WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH TO ROLE cortex_agent_slack_role;

-- Set context for subsequent scripts
USE WAREHOUSE SFE_CORTEX_AGENT_SLACK_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;

SELECT 'Schema and warehouse created' AS status;
