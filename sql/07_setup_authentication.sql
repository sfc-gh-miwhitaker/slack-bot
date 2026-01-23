/*******************************************************************************
 * Step 7: PAT Authentication Setup
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 ******************************************************************************/

USE ROLE cortex_agent_slack_role;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;

-- Create authentication policy for PAT access
CREATE OR REPLACE AUTHENTICATION POLICY SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.pat_auth_policy
    PAT_POLICY = (NETWORK_POLICY_EVALUATION = ENFORCED_NOT_REQUIRED)
    COMMENT = 'DEMO: PAT authentication for Slack integration (Expires: 2026-02-22)';

-- Apply to current user
SET current_user = (SELECT CURRENT_USER());
ALTER USER IDENTIFIER($current_user) SET AUTHENTICATION POLICY SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.pat_auth_policy;

SELECT 'PAT authentication configured' AS status;
SELECT 'Next: Create a PAT in Snowsight > User menu > Profile > Programmatic access tokens' AS instruction;
