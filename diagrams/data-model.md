# Data Model

> **Author:** SE Community
> **Project:** Cortex Agent Slack Integration
> **Last Updated:** 2026-01-23

## Entity Relationship Diagram

```mermaid
erDiagram
    PATIENTS ||--o{ PROCEDURES : "has"
    PATIENTS ||--o{ DIAGNOSES : "receives"

    PATIENTS {
        NUMBER patient_id PK
        VARCHAR first_name
        VARCHAR last_name
        DATE date_of_birth
        VARCHAR gender
        VARCHAR blood_type
        VARCHAR insurance_provider
        VARCHAR primary_physician
    }

    PROCEDURES {
        NUMBER procedure_id PK
        NUMBER patient_id FK
        DATE procedure_date
        VARCHAR procedure_type
        VARCHAR department
        VARCHAR physician
        NUMBER duration_minutes
        NUMBER cost_usd
        VARCHAR status
    }

    DIAGNOSES {
        NUMBER diagnosis_id PK
        NUMBER patient_id FK
        DATE diagnosis_date
        VARCHAR icd_code
        VARCHAR diagnosis_name
        VARCHAR severity
        VARCHAR treating_physician
    }
```

## Semantic View

The `SV_CORTEX_AGENT_SLACK_MEDICAL` semantic view joins all three tables to provide a unified interface for Cortex Analyst queries.

```mermaid
flowchart LR
    subgraph Base Tables
        P[PATIENTS]
        PR[PROCEDURES]
        D[DIAGNOSES]
    end

    subgraph Semantic Layer
        SV[SV_CORTEX_AGENT_SLACK_MEDICAL]
    end

    P --> SV
    PR --> SV
    D --> SV

    SV --> |DIMENSIONS| DIM[patient_id, gender, department, severity, ...]
    SV --> |METRICS| MET[patient_count, procedure_count, total_cost, ...]
    SV --> |VERIFIED_QUERIES| VQ[5 pre-verified SQL queries]
```

## Notes

- All tables reside in `SNOWFLAKE_EXAMPLE.CORTEX_AGENT_SLACK` schema
- Semantic view resides in `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS` schema
- Patient-to-procedure and patient-to-diagnosis relationships are 1:many
- Synthetic data: 500 patients, ~2000 procedures, ~1500 diagnoses
