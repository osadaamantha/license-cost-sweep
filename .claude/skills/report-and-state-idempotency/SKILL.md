---
name: report-and-state-idempotency
description: Write or review code that produces licence-waste reports and tracks per-tenant run state. Use for Excel report generation, blob storage writes to reports/run-state, idempotency, and partial-failure handling.
---

# Report & State Idempotency

**No storage account, blob containers, or report code exist yet.** This skill describes the intended pattern, mirrored from the sibling mailbox-audit-sweep repo: two blob containers (`reports` for generated Excel workbooks, `run-state` for per-tenant idempotency state) on a planned storage account (`stliccostprod`). If that account is provisioned with `allowSharedKeyAccess: false` (the sibling's convention), every blob call needs `--auth-mode login` (CLI) or Entra-based auth (SDK) — account keys/connection strings will not work. Confirm the actual provisioned configuration once `infra/` exists rather than assuming it matches this description.

## Report generation

- One report workbook per client tenant per run — never combine two clients' findings into one workbook, and never combine two clients' tickets/notifications either (see `license-cost-safety`).
- Key each report and state entry by tenant identifier + run id, so a re-run or retry doesn't silently overwrite a different tenant's output or a previous run's history.
- Report figures should distinguish confirmed waste (e.g. a disabled account with a directly-assigned licence) from figures that depend on an external cost input (see `graph-exchange-readonly`'s note that Graph exposes no pricing) — never present an estimated dollar saving as if it came from a verified source.

## Idempotency

- Before writing a report for a (tenant, run) pair, check `run-state` for whether that pair already completed — a retried run must not duplicate a report or a downstream ticket.
- Write `run-state` as the last step of a successful tenant run, not the first — state should reflect completed work, not attempted work, so a crash mid-run doesn't falsely mark that tenant done.

## Partial failure

- A single client's failure must not abort the run for other clients — catch it, record it, move to the next tenant (same rule as `graph-exchange-readonly`'s resilience section).
- Retain partial-failure records rather than discarding them — a client that failed should be visibly absent from "succeeded" state, not silently missing with no trace of why.
- Missing or unavailable evidence within a client's data becomes `Unknown` in the report, never an inferred finding (see `CLAUDE.md`).

## What never goes in a report or log

Mailbox contents, subjects, tokens, private keys, credentials, licence cost figures sourced from a client-specific contract, or the client spreadsheet/ITGlue data used to configure a tenant — reports carry only the licence-waste findings they exist to convey.
