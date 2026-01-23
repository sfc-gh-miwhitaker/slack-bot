"""
Cortex Agent + Slack Integration
Reference implementation for integrating Snowflake Cortex Agents with Slack.
"""

import os
import re
import json
import tempfile
from typing import Optional
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler
import snowflake.connector
from dotenv import load_dotenv

from cortex_agent import CortexAgent
from charts import ChartGenerator

load_dotenv()

ACCOUNT = os.getenv("ACCOUNT")
USER = os.getenv("DEMO_USER")
ROLE = os.getenv("DEMO_USER_ROLE", "cortex_agent_slack_role")
WAREHOUSE = os.getenv("WAREHOUSE", "SFE_CORTEX_AGENT_SLACK_WH")
SLACK_APP_TOKEN = os.getenv("SLACK_APP_TOKEN")
SLACK_BOT_TOKEN = os.getenv("SLACK_BOT_TOKEN")
AGENT_ENDPOINT = os.getenv("AGENT_ENDPOINT")
PAT = os.getenv("PAT")

app = App(token=SLACK_BOT_TOKEN)
chart_gen = ChartGenerator()

CORTEX_AGENT: Optional[CortexAgent] = None
SNOWFLAKE_CONN = None


def get_snowflake_connection():
    """Create Snowflake connection using PAT authentication."""
    try:
        if not ACCOUNT:
            print("No account identifier found - set ACCOUNT env var")
            return None

        conn = snowflake.connector.connect(
            user=USER,
            password=PAT,
            account=ACCOUNT,
            warehouse=WAREHOUSE,
            role=ROLE
        )

        cursor = conn.cursor()
        cursor.execute("SELECT CURRENT_VERSION()")
        row = cursor.fetchone()
        version = row[0] if row else "unknown"
        cursor.close()

        print(f"Connected to Snowflake v{version}")
        return conn

    except Exception as e:
        print(f"Snowflake connection failed: {e}")
        return None


def upload_chart_to_slack(client, channel: str, chart_path: str, title: str) -> bool:
    """Upload a chart image to Slack."""
    try:
        with open(chart_path, 'rb') as f:
            client.files_upload_v2(
                channel=channel,
                file=f,
                filename=f"{title.replace(' ', '_')}.png",
                title=title
            )
        return True
    except Exception as e:
        print(f"Chart upload failed: {e}")
        return False


def format_for_slack(text: str) -> str:
    """Convert markdown to Slack mrkdwn format."""
    if not text:
        return text
    text = re.sub(r'\*\*(.*?)\*\*', r'*\1*', text)
    text = re.sub(r'__(.*?)__', r'*\1*', text)
    return text


def create_thinking_block(status: str, steps: list = None, is_complete: bool = False) -> list:
    """Create Slack blocks for thinking/reasoning display."""
    if is_complete:
        step_count = len(steps) if steps else 0
        header = f"*Thinking...* Complete ({step_count} steps)"
    else:
        header = f"*Thinking...* {status}"

    blocks = [
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": header}
        }
    ]

    if is_complete and steps:
        blocks.append({
            "type": "actions",
            "elements": [{
                "type": "button",
                "text": {"type": "plain_text", "text": "Show Details"},
                "action_id": "show_thinking_details",
                "value": json.dumps({"steps": steps[-20:]})
            }]
        })

    return blocks


def create_response_blocks(response: dict) -> list:
    """Create Slack blocks for the agent response."""
    blocks = []

    if response.get('text'):
        formatted_text = format_for_slack(response['text'])

        if len(formatted_text) > 2900:
            formatted_text = formatted_text[:2900] + "..."

        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Response:*\n{formatted_text}"
            }
        })

    if response.get('verified_query_used'):
        blocks.append({
            "type": "context",
            "elements": [{
                "type": "mrkdwn",
                "text": "*Verified Query* - Answer accuracy verified by agent owner"
            }]
        })

    if response.get('citations'):
        citations_text = format_for_slack(response['citations'])
        if len(citations_text) > 500:
            citations_text = citations_text[:500] + "..."
        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Sources:*\n_{citations_text}_"
            }
        })

    if response.get('suggestions'):
        suggestions = response['suggestions'][:3]
        suggestions_text = "\n".join(f"- {s}" for s in suggestions)
        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Try asking:*\n{suggestions_text}"
            }
        })

    return blocks


@app.message("hello")
def handle_hello(message, say):
    """Handle hello message with welcome info."""
    say(
        blocks=[
            {
                "type": "header",
                "text": {"type": "plain_text", "text": "Snowflake Cortex Agent"}
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "I can help you analyze support tickets and search company documents.\n\n*Try asking:*\n- _How many tickets by service type?_\n- _What are the payment terms for Snowtires?_\n- _Show contact preference breakdown_"
                }
            }
        ]
    )


@app.event("app_mention")
def handle_mention(event, say, client):
    """Handle @mentions of the bot."""
    process_message(event, say, client)


@app.message(re.compile(".*"))
def handle_dm(message, say, client):
    """Handle direct messages."""
    if message.get('channel_type') == 'im':
        process_message(message, say, client)


def process_message(event: dict, say, client):
    """Main message processing with streaming updates."""
    global CORTEX_AGENT

    user_message = event.get('text', '').strip()
    user_message = re.sub(r'<@\w+>', '', user_message).strip()

    if not user_message:
        say("Hi! Ask me anything about support tickets or company documents.")
        return

    if not CORTEX_AGENT:
        say("Agent not initialized. Please check configuration.")
        return

    channel = event.get('channel')

    initial_msg = say(
        text="Processing...",
        blocks=[
            {"type": "divider"},
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*Snowflake Cortex Agent* is processing your request..."
                }
            }
        ]
    )

    thinking_msg = say(
        text="Thinking...",
        blocks=create_thinking_block("Starting...")
    )
    thinking_ts = thinking_msg.get('ts') if thinking_msg else None

    def on_status_update(status: str, steps: list):
        """Callback for real-time status updates."""
        if thinking_ts and channel:
            try:
                client.chat_update(
                    channel=channel,
                    ts=thinking_ts,
                    blocks=create_thinking_block(status, steps)
                )
            except Exception as e:
                print(f"Status update failed: {e}")

    try:
        response = CORTEX_AGENT.chat(user_message, on_status=on_status_update)

        if thinking_ts and channel:
            try:
                steps = getattr(CORTEX_AGENT, 'planning_steps', [])
                client.chat_update(
                    channel=channel,
                    ts=thinking_ts,
                    blocks=create_thinking_block("", steps, is_complete=True)
                )
            except Exception:
                pass

        response_blocks = create_response_blocks(response)
        if response_blocks:
            say(text="Response", blocks=response_blocks)

        if response.get('sql_queries') and response.get('data'):
            try:
                chart_info = chart_gen.analyze_and_generate(
                    response['data'],
                    user_message,
                    response.get('sql_queries', [])
                )

                if chart_info and chart_info.get('path'):
                    upload_chart_to_slack(
                        client,
                        channel,
                        chart_info['path'],
                        chart_info.get('title', 'Data Visualization')
                    )

                    if os.path.exists(chart_info['path']):
                        os.remove(chart_info['path'])

            except Exception as e:
                print(f"Chart generation failed: {e}")

    except Exception as e:
        print(f"Error: {e}")
        say(f"Sorry, an error occurred: {str(e)}")


@app.action("show_thinking_details")
def handle_thinking_details(ack, body, client):
    """Handle the Show Details button click."""
    ack()

    try:
        value = json.loads(body["actions"][0]["value"])
        steps = value.get("steps", [])
        channel = body["channel"]["id"]
        ts = body["message"]["ts"]

        steps_text = "\n".join(f"- {step}" for step in steps)
        if len(steps_text) > 2800:
            steps_text = steps_text[:2800] + "\n_...truncated_"

        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Thinking Steps:*\n{steps_text}"
                }
            },
            {
                "type": "actions",
                "elements": [{
                    "type": "button",
                    "text": {"type": "plain_text", "text": "Hide Details"},
                    "action_id": "hide_thinking_details",
                    "value": json.dumps({"steps": steps})
                }]
            }
        ]

        client.chat_update(channel=channel, ts=ts, blocks=blocks)

    except Exception as e:
        print(f"Error showing details: {e}")


@app.action("hide_thinking_details")
def handle_hide_details(ack, body, client):
    """Handle the Hide Details button click."""
    ack()

    try:
        value = json.loads(body["actions"][0]["value"])
        steps = value.get("steps", [])
        channel = body["channel"]["id"]
        ts = body["message"]["ts"]

        client.chat_update(
            channel=channel,
            ts=ts,
            blocks=create_thinking_block("", steps, is_complete=True)
        )

    except Exception as e:
        print(f"Error hiding details: {e}")


def init():
    """Initialize connections."""
    global CORTEX_AGENT, SNOWFLAKE_CONN

    print("Initializing Cortex Agent + Slack...")

    SNOWFLAKE_CONN = get_snowflake_connection()

    CORTEX_AGENT = CortexAgent(
        agent_url=AGENT_ENDPOINT,
        pat=PAT,
        connection=SNOWFLAKE_CONN
    )

    print("Initialization complete")
    return SNOWFLAKE_CONN, CORTEX_AGENT


if __name__ == "__main__":
    SNOWFLAKE_CONN, CORTEX_AGENT = init()

    if SNOWFLAKE_CONN:
        print("Starting Slack bot...")
        SocketModeHandler(app, SLACK_APP_TOKEN).start()
    else:
        print("Failed to connect. Check your configuration.")
