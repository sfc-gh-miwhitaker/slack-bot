# Network Flow

> **Author:** SE Community
> **Project:** Cortex Agent Slack Integration
> **Last Updated:** 2026-01-23

## Network Topology

```mermaid
flowchart TB
    subgraph Slack Cloud
        SW[Slack Workspace]
        SA[Slack API Gateway]
    end

    subgraph Local Environment
        BOT[Python Bot<br/>Socket Mode]
    end

    subgraph Snowflake Cloud
        API[Cortex Agent API<br/>HTTPS REST]
        AG[medical_assistant<br/>Agent]
        CA[Cortex Analyst]
        WH[SFE_CORTEX_AGENT_SLACK_WH]
        DB[(SNOWFLAKE_EXAMPLE<br/>Database)]
    end

    SW <-->|WebSocket<br/>Socket Mode| BOT
    BOT -->|HTTPS POST<br/>Bearer PAT| API
    API --> AG
    AG --> CA
    CA --> WH
    WH --> DB

    BOT -->|Snowflake Connector<br/>PAT Auth| WH
```

## Connection Details

### Slack Connection (Outbound from Bot)

| Property | Value |
|----------|-------|
| Protocol | WebSocket (Socket Mode) |
| Authentication | `SLACK_APP_TOKEN` (xapp-...) |
| Bot Identity | `SLACK_BOT_TOKEN` (xoxb-...) |
| Direction | Bot initiates, bidirectional messages |
| Port | 443 (WSS) |

### Cortex Agent API (Outbound from Bot)

| Property | Value |
|----------|-------|
| Protocol | HTTPS |
| Endpoint | `https://{org}-{account}.snowflakecomputing.com/api/v2/databases/snowflake_intelligence/schemas/agents/agents/medical_assistant:run` |
| Authentication | Programmatic Access Token (PAT) |
| Header | `X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN` |
| Port | 443 |

### Snowflake Connector (Outbound from Bot)

| Property | Value |
|----------|-------|
| Protocol | HTTPS |
| Authentication | PAT (via password parameter) |
| Role | `cortex_agent_slack_role` |
| Warehouse | `SFE_CORTEX_AGENT_SLACK_WH` |
| Port | 443 |

## Firewall Requirements

```mermaid
flowchart LR
    subgraph Allowed Outbound
        direction TB
        O1[wss://*.slack.com:443]
        O2[https://*.snowflakecomputing.com:443]
    end

    BOT[Bot Host] --> O1
    BOT --> O2
```

No inbound connections required - Socket Mode eliminates need for public endpoints.
