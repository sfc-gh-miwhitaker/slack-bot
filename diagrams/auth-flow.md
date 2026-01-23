# Authentication Flow

> **Author:** SE Community
> **Project:** Cortex Agent Slack Integration
> **Last Updated:** 2026-01-23

## Authentication Overview

```mermaid
flowchart TB
    subgraph Credentials
        PAT[Snowflake PAT<br/>Programmatic Access Token]
        SAT[Slack App Token<br/>xapp-...]
        SBT[Slack Bot Token<br/>xoxb-...]
    end

    subgraph Services
        SLACK[Slack API]
        AGENT[Cortex Agent API]
        SF[Snowflake Connector]
    end

    SAT -->|Socket Mode auth| SLACK
    SBT -->|Bot identity| SLACK
    PAT -->|Bearer token| AGENT
    PAT -->|Password param| SF
```

## Slack Authentication

```mermaid
sequenceDiagram
    participant Bot
    participant Slack

    Note over Bot,Slack: App-Level Token (Socket Mode)
    Bot->>Slack: Connect with SLACK_APP_TOKEN
    Slack->>Bot: WebSocket connection established

    Note over Bot,Slack: Bot Token (API Operations)
    Bot->>Slack: chat.postMessage + SLACK_BOT_TOKEN
    Slack->>Bot: Message sent confirmation
```

### Token Types

| Token | Purpose | Format | Scopes |
|-------|---------|--------|--------|
| App Token | Socket Mode connection | `xapp-...` | `connections:write` |
| Bot Token | Bot API operations | `xoxb-...` | `app_mentions:read`, `chat:write`, `files:write`, `im:history`, `im:read`, `im:write` |

## Snowflake PAT Authentication

```mermaid
sequenceDiagram
    participant User as Snowflake User
    participant Snowsight
    participant Bot
    participant Cortex as Cortex Agent API
    participant Connector as Snowflake Connector

    Note over User,Snowsight: One-time PAT creation
    User->>Snowsight: Create PAT with cortex_agent_slack_role
    Snowsight->>User: Return PAT string

    Note over Bot,Cortex: Runtime - Agent API
    Bot->>Cortex: POST with Bearer {PAT}
    Cortex->>Cortex: Validate PAT, assume role
    Cortex->>Bot: Streaming response

    Note over Bot,Connector: Runtime - Direct queries
    Bot->>Connector: Connect with PAT as password
    Connector->>Connector: Authenticate, assume role
    Connector->>Bot: Connection established
```

### PAT Configuration

| Property | Value |
|----------|-------|
| Creation Location | Snowsight > User Menu > Profile > Programmatic access tokens |
| Associated Role | `cortex_agent_slack_role` |
| Permissions | Access to agent, semantic view, warehouse |
| Auth Policy | `pat_auth_policy` (NETWORK_POLICY_EVALUATION = ENFORCED_NOT_REQUIRED) |

## Role Permissions

```mermaid
flowchart TD
    subgraph cortex_agent_slack_role
        P1[CREATE DATABASE ON ACCOUNT]
        P2[CREATE WAREHOUSE ON ACCOUNT]
        P3[SNOWFLAKE.CORTEX_USER database role]
        P4[USAGE ON snowflake_intelligence]
        P5[USAGE ON AGENT medical_assistant]
        P6[SELECT ON semantic view]
    end

    ROLE[cortex_agent_slack_role] --> P1
    ROLE --> P2
    ROLE --> P3
    ROLE --> P4
    ROLE --> P5
    ROLE --> P6
```

## Security Notes

1. **No secrets in code** - All credentials loaded via `os.getenv()`
2. **PAT rotation** - PATs can be revoked/rotated without code changes
3. **Minimal permissions** - Role has only required grants
4. **Socket Mode** - No public webhook endpoint needed (no inbound firewall rules)
