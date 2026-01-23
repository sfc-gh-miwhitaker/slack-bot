#!/bin/bash
set -e

cd "$(dirname "$0")/.."

if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo "Virtual environment not found. Run: python3 -m venv .venv && source .venv/bin/activate && pip install -r bot/requirements.txt"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo ".env file not found. Copy .env.example to .env and configure."
    exit 1
fi

echo "Starting Cortex Agent + Slack..."
python bot/app.py
