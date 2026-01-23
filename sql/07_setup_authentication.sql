/*******************************************************************************
 * Step 7: PAT Authentication Setup (MANUAL - Run Line-by-Line)
 * PROJECT: Cortex Agent Slack Integration
 * EXPIRES: 2026-02-22
 *
 * ⚠️  DO NOT RUN WITH "Run All" - Execute each statement individually
 *
 * This step is intentionally separate because you must:
 *   1. Create the authentication policy (below)
 *   2. Create a PAT in Snowsight UI
 *   3. COPY THE PAT VALUE (shown only once!)
 *   4. Store in your .env file as SNOWFLAKE_PAT
 ******************************************************************************/

-- ============================================================================
-- STEP 7a: Set context
-- ============================================================================
USE ROLE cortex_agent_slack_role;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_AGENT_SLACK;

-- ============================================================================
-- STEP 7b: Create authentication policy
-- ============================================================================
CREATE OR REPLACE AUTHENTICATION POLICY SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.pat_auth_policy
    PAT_POLICY = (NETWORK_POLICY_EVALUATION = ENFORCED_NOT_REQUIRED)
    COMMENT = 'DEMO: PAT authentication for Slack integration (Expires: 2026-02-22)';

-- ============================================================================
-- STEP 7c: Apply policy to your user
-- ============================================================================
SET current_user = (SELECT CURRENT_USER());
ALTER USER IDENTIFIER($current_user) SET AUTHENTICATION POLICY SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK.pat_auth_policy;

-- ============================================================================
-- STEP 7d: Create PAT in Snowsight UI
-- ============================================================================
-- 1. Click your username (bottom-left) → Profile
-- 2. Scroll to "Programmatic access tokens"
-- 3. Click "+ Token"
-- 4. Name: "slack-bot-pat"
-- 5. Role: cortex_agent_slack_role
-- 6. Warehouse: SFE_CORTEX_AGENT_SLACK_WH
-- 7. Expiration: 30 days (or match demo expiration)
-- 8. Click "Generate"
-- 9. ⚠️  COPY THE TOKEN NOW - It will not be shown again!
--
-- Store in your .env file:
--   SNOWFLAKE_PAT=<your-copied-token>
