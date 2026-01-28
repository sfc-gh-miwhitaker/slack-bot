![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--02--22-orange)

# Cortex Agent Slack Integration

> DEMONSTRATION PROJECT - EXPIRES: 2026-02-22
> This demo uses Snowflake features current as of January 2026.
> After expiration, this repository will be archived and made private.

**Author:** SE Community
**Purpose:** Reference implementation for integrating Snowflake Cortex Agents with Slack
**Created:** 2026-01-23 | **Expires:** 2026-02-22 (30 days) | **Status:** ACTIVE

---

## First Time Here?

Run these in order:

| Step | Action | Location |
|------|--------|----------|
| 1 | Run `deploy_all.sql` (click Run All) | Snowsight |
| 2 | Create PAT (Profile → Programmatic access tokens) | Snowsight |
| 3 | Create Slack app, copy tokens | [api.slack.com/apps](https://api.slack.com/apps) |
| 4 | Copy `.env.example` → `.env`, fill in values | Local |
| 5 | `pip install -r bot/requirements.txt && python bot/app.py` | Terminal |

**Prerequisites:** Snowflake account with Cortex access, Slack workspace admin access, Python 3.10+

---

## What Gets Created

| Object | Name | Owner |
|--------|------|-------|
| Database | `SNOWFLAKE_EXAMPLE` | SYSADMIN |
| Schema | `SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK` | SYSADMIN |
| Schema | `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS` | SYSADMIN |
| Warehouse | `SFE_CORTEX_AGENT_SLACK_WH` | SYSADMIN |
| Role | `cortex_agent_slack_role` | ACCOUNTADMIN |
| Tables | `patients`, `procedures`, `diagnoses` | App Role |
| Semantic View | `SV_CORTEX_AGENT_SLACK_MEDICAL` | App Role |
| Agent | `medical_assistant` | App Role |

Sample data: 500 patients, 2,000 procedures, 1,500 diagnoses

---

## Detailed Steps

### Step 1: Deploy Snowflake Objects

1. Open [Snowsight](https://app.snowflake.com)
2. Open `deploy_all.sql` from repository root
3. Copy entire contents to a new SQL worksheet
4. Click **Run All**

### Step 2: Create PAT

1. In Snowsight, click your username (bottom-left) → **Profile**
2. Scroll to **Programmatic access tokens** → **+ Token**
3. Role: `cortex_agent_slack_role`
4. Warehouse: `SFE_CORTEX_AGENT_SLACK_WH`
5. **Copy the token immediately** - shown only once!

### Step 3: Create Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App** → **From an app manifest**
3. Select your workspace, then paste this manifest:

```json
{
    "display_information": {
        "name": "Medical Analytics Bot"
    },
    "features": {
        "app_home": {
            "home_tab_enabled": false,
            "messages_tab_enabled": true,
            "messages_tab_read_only_enabled": false
        },
        "bot_user": {
            "display_name": "Medical Analytics Bot",
            "always_online": true
        }
    },
    "oauth_config": {
        "scopes": {
            "bot": [
                "app_mentions:read",
                "chat:write",
                "files:write",
                "im:history",
                "im:read",
                "im:write"
            ]
        }
    },
    "settings": {
        "event_subscriptions": {
            "bot_events": [
                "app_mention",
                "message.im"
            ]
        },
        "interactivity": {
            "is_enabled": true
        },
        "org_deploy_enabled": false,
        "socket_mode_enabled": true,
        "token_rotation_enabled": false
    }
}
```

4. Click **Create**
5. Go to **Basic Information** → **App-Level Tokens** → **Generate Token**
   - Name: `socket`, Scope: `connections:write`
   - Copy the **App Token** (`xapp-...`)
6. Go to **Install App** → **Install to Workspace** → **Allow**
7. Copy the **Bot Token** (`xoxb-...`) that appears

### Step 4: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your values:

| Variable | Where to Get It |
|----------|-----------------|
| `ACCOUNT` | Your Snowflake account identifier (e.g., `orgname-accountname`) |
| `DEMO_USER` | Your Snowflake username |
| `PAT` | From Step 2 (the token you copied) |
| `SLACK_APP_TOKEN` | From Step 3 (`xapp-...`) |
| `SLACK_BOT_TOKEN` | From Step 3 (`xoxb-...`) |

### Step 5: Run

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r bot/requirements.txt
python bot/app.py
```

You should see: `⚡️ Bolt app is running!`

---

## Example Queries

Message the bot in Slack:

- "How many procedures by department?"
- "What is the total revenue by department?"
- "Show me patients by insurance provider"
- "What are the most common diagnoses?"
- "Breakdown of diagnosis severity"
- "Average procedure cost by department"

### Query with Auto-Generated Chart

Ask a question and get both a text response with insights and an automatically generated visualization:

![Query with chart](assets/demo-query-chart.png)

### Follow-up with Conversation Context

Ask follow-up questions naturally - the bot remembers the conversation context:

![Follow-up with context](assets/demo-followup-context.png)

---

## Architecture

```mermaid
flowchart LR
    U[User] -->|Slack| B[Bot]
    B -->|REST API| A[Cortex Agent]
    A --> CA[Cortex Analyst]
    CA --> SV[Semantic View]
    SV --> P[(Patients)]
    SV --> PR[(Procedures)]
    SV --> D[(Diagnoses)]
```

See [`diagrams/`](diagrams/) for detailed architecture diagrams.

---

## Understanding the Core

Want to see the minimal integration without charts or streaming?

See [`bot/example_cortex_minimal.py`](bot/example_cortex_minimal.py) - ~60 lines showing the essential Cortex Agent API call:

```bash
pip install slack-bolt requests python-dotenv
python bot/example_cortex_minimal.py
```

This requires the same environment variables from Steps 2-4.

---

## Cleanup

Remove all demo objects:

```sql
-- Run in Snowsight
-- Open sql/99_cleanup.sql and click Run All
```

**Protected (not removed):** `SNOWFLAKE_EXAMPLE` database, `SEMANTIC_MODELS` schema, `GIT_REPOS` schema, `SFE_GIT_API_INTEGRATION`

---

## License

Apache 2.0
