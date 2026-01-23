# Data Flow

> **Author:** SE Community
> **Project:** Cortex Agent Slack Integration
> **Last Updated:** 2026-01-23

## Query Processing Flow

```mermaid
sequenceDiagram
    autonumber
    participant U as User (Slack)
    participant B as Slack Bot
    participant A as Cortex Agent API
    participant CA as Cortex Analyst
    participant SV as Semantic View
    participant WH as Warehouse

    U->>B: Natural language question
    B->>B: Extract text, remove @mention
    B->>U: "Processing..." message

    B->>A: POST /agents/medical_assistant:run
    Note over A: Streaming response begins

    A->>CA: Route to cortex_analyst_text_to_sql tool
    CA->>SV: Interpret against semantic model
    SV->>CA: Return SQL query

    CA->>WH: Execute generated SQL
    WH->>CA: Query results

    CA->>A: Structured response + SQL + data
    A-->>B: Stream: status, thinking, text, tool_result

    B->>B: Parse response, extract SQL
    B->>WH: Re-execute SQL (for charting)
    WH->>B: DataFrame results

    B->>B: Generate chart (if applicable)
    B->>U: Response message
    B->>U: Chart image (if generated)
```

## Response Processing

```mermaid
flowchart TD
    subgraph Cortex Agent Response
        R[Streaming Response]
        R --> S[response.status events]
        R --> TH[response.thinking events]
        R --> TX[response.text.delta events]
        R --> TR[response.tool_result events]
    end

    subgraph Bot Processing
        S --> |Planning steps| PS[Display thinking indicator]
        TH --> |Reasoning| PS
        TX --> |Accumulated text| FM[Format for Slack]
        TR --> |SQL + verified flag| SQL[Extract SQL queries]
    end

    subgraph Output
        FM --> MSG[Slack message blocks]
        SQL --> |If data returned| CH[Chart generation]
        CH --> IMG[Upload chart image]
    end
```

## Data Transformation Points

| Stage | Input | Output | Location |
|-------|-------|--------|----------|
| User Input | Raw Slack message | Cleaned text | `app.py:process_message()` |
| Agent Request | Text query | Streaming HTTP response | `cortex_agent.py:_stream_request()` |
| SQL Extraction | Tool result JSON | SQL string | `cortex_agent.py:_process_tool_result()` |
| Query Execution | SQL string | pandas DataFrame | `cortex_agent.py:_execute_sql()` |
| Chart Generation | DataFrame + question | PNG image path | `charts.py:analyze_and_generate()` |
| Slack Formatting | Response dict | Slack blocks | `app.py:create_response_blocks()` |
