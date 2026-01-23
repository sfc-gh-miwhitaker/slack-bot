"""
Minimal Slack Bot Example
=========================
Copy this file to start your own Slack bot.
No Snowflake dependencies - just Slack.

Setup:
1. Create app at api.slack.com/apps
2. Enable Socket Mode
3. Add scopes: app_mentions:read, chat:write, im:history, im:read, im:write
4. Subscribe to events: app_mention, message.im
5. Install to workspace

Run:
    pip install slack-bolt python-dotenv
    export SLACK_APP_TOKEN=xapp-...
    export SLACK_BOT_TOKEN=xoxb-...
    python example_minimal.py
"""

import os
import re
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

app = App(token=os.environ["SLACK_BOT_TOKEN"])


@app.message("hello")
def handle_hello(message, say):
    """Respond to 'hello' messages."""
    user = message["user"]
    say(f"Hey <@{user}>! How can I help?")


@app.event("app_mention")
def handle_mention(event, say):
    """Respond to @mentions."""
    text = re.sub(r'<@\w+>', '', event.get('text', '')).strip()
    say(f"You said: {text}")


@app.message(re.compile(".*"))
def handle_dm(message, say):
    """Respond to direct messages."""
    if message.get('channel_type') == 'im':
        say(f"Got your message: {message.get('text', '')}")


if __name__ == "__main__":
    print("Starting Slack bot...")
    SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"]).start()
