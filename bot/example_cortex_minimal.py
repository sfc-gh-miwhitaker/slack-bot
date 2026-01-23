"""
Minimal Cortex Agent + Slack Integration
========================================
Copy this file to start your own Cortex Agent Slack bot.
~60 lines of code - no charts, no streaming, just the essentials.

Prerequisites:
1. Cortex Agent deployed (run sql/deploy_all.sql)
2. Slack app with Socket Mode enabled
3. PAT token created in Snowsight

Run:
    pip install slack-bolt requests python-dotenv
    export SLACK_APP_TOKEN=xapp-...
    export SLACK_BOT_TOKEN=xoxb-...
    export PAT=your_programmatic_access_token
    export AGENT_ENDPOINT=https://org-account.snowflakecomputing.com/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_AGENT_SLACK/agents/medical_assistant:run
    python example_cortex_minimal.py
"""

import os
import re
import json
import requests
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

app = App(token=os.environ["SLACK_BOT_TOKEN"])

AGENT_ENDPOINT = os.environ["AGENT_ENDPOINT"]
PAT = os.environ["PAT"]


def ask_cortex_agent(question: str) -> str:
    """Send a question to Cortex Agent and return the response text."""
    response = requests.post(
        AGENT_ENDPOINT,
        headers={
            "Authorization": f"Bearer {PAT}",
            "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
            "Content-Type": "application/json",
        },
        json={
            "messages": [{"role": "user", "content": [{"type": "text", "text": question}]}],
            "stream": False,
        },
        timeout=60,
    )
    response.raise_for_status()

    # Extract text from response
    data = response.json()
    for item in data.get("choices", [{}])[0].get("message", {}).get("content", []):
        if item.get("type") == "text":
            return item.get("text", "No response")
    return "No response"


@app.event("app_mention")
def handle_mention(event, say):
    """Respond to @mentions with Cortex Agent answers."""
    question = re.sub(r"<@\w+>", "", event.get("text", "")).strip()
    if not question:
        say("Ask me anything about the medical data!")
        return

    say("Thinking...")
    try:
        answer = ask_cortex_agent(question)
        say(answer)
    except Exception as e:
        say(f"Error: {e}")


@app.message(re.compile(".*"))
def handle_dm(message, say):
    """Handle direct messages."""
    if message.get("channel_type") == "im":
        question = message.get("text", "").strip()
        say("Thinking...")
        try:
            answer = ask_cortex_agent(question)
            say(answer)
        except Exception as e:
            say(f"Error: {e}")


if __name__ == "__main__":
    print("Starting Cortex Agent Slack bot...")
    SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"]).start()
