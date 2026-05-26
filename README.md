# Banco Un — Financial Reconciliation Model

SQL-based financial reconciliation system built on a simulated credit card operation.

## Context

**Banco Un** is a fictional digital bank with a growing credit card portfolio. This project models the reconciliation process between operational transactions and accounting entries — a critical process in any financial institution's monthly close.

The reconciliation identifies:
- Transactions without a corresponding accounting entry
- Accounting entries without an originating transaction (manual adjustments)
- Value discrepancies between matched pairs
- Entries posted to the wrong accounting period

## Data Model

Seven tables representing the full credit card lifecycle:

```
clientes
└── contas
    └── cartoes
        ├── transacoes ──── lancamentos_contabeis
        └── faturas
            └── pagamentos ── lancamentos_contabeis
```

| Table | Role |
|---|---|
| `clientes` | Root entity — all relationships flow from here |
| `contas` | Links client to banking product |
| `cartoes` | Credit limit, validity, card status |
| `transacoes` | Every purchase, reversal or cash advance |
| `faturas` | Monthly billing cycle |
| `pagamentos` | Bill payments by the client |
| `lancamentos_contabeis` | Accounting entry for every financial event |

## SQL Scripts

| File | Description |
|---|---|
| `sql/01_create_tables.sql` | Full schema — all 7 tables with types and comments |
| `sql/02_seed_data.sql` | Initial dataset with intentional divergences planted |
| `sql/03_reconciliacao.sql` | Reconciliation queries — finds all divergence types |

## Divergence Types Modeled

| Type | How it appears | Business impact |
|---|---|---|
| Transaction without entry | Approved transaction, no accounting record | Understated liabilities |
| Entry without transaction | Manual adjustment, no operational origin | Unauditable entry |
| Value mismatch | Matched pair with different amounts | Incorrect balance |
| Wrong accounting period | Transaction in May, entry posted to January | Misaligned monthly close |

## How to Run

```bash
# Install DuckDB CLI
# https://duckdb.org/docs/installation

# Create the database
duckdb banco_un.db

# Run scripts in order
.read sql/01_create_tables.sql
.read sql/02_seed_data.sql
.read sql/03_reconciliacao.sql
```

## Project Series

This is **Project 1 of 3**:

| Project | Focus | Stack |
|---|---|---|
| P1 — Reconciliation *(this repo)* | Find divergences between transactions and accounting | SQL |
| P2 — Data Quality | Monitor data quality at the source | SQL + Python |
| P3 — Regulatory Pipeline | Transform raw data into Central Bank reporting | SQL + Scala |

The three projects tell a single story: *reconciled → monitored the source → automated the pipeline.*
