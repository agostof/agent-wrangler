# Skill: Codebase Inspection, Documentation, and Test Planning

## Goal

Analyze a codebase, generate structured documentation according to repository rules, then produce a test strategy and begin implementation.

---

## Precondition

The repository contains a documentation policy file:

Documentation-Rules.md

This file is the canonical authority for documentation structure and placement.

---

## Core Principles

- Do not assume behavior not supported by code
- Prefer explicit structure over narrative summaries
- Separate analysis, planning, and implementation phases
- Produce artifacts that persist across phases
- When uncertain, document the uncertainty

---

## Phase 0 — Load Documentation Rules

1. Locate and read:
   Documentation-Rules.md

2. Extract:
   - directory structure rules
   - audience definitions
   - placement constraints

3. Apply these rules strictly in all following phases

Do NOT duplicate the rules into generated documents.

---

## Phase 1 — Inspection

Analyze the codebase and identify:

- architecture (layers, services, modules)
- entry points (server startup, CLI, jobs)
- API endpoints (routes, methods, payloads)
- authentication and authorization mechanisms
- data models and schema usage
- database access patterns (ORM/raw queries)
- environment variables and configuration
- external services and integrations
- error handling patterns
- security considerations
- testability constraints

---

## Phase 2 — Documentation

Create or update documentation according to Documentation-Rules.md.

### Required Outputs (only if supported by evidence)

In `docs/`:
- API-spec.md
- architecture.md
- data-model.md
- security.md

In `agent-docs/`:
- context.md (system assumptions, constraints)
- conventions.md (naming, patterns, expectations)

In `operator-docs/`:
- deployment.md
- configuration.md

### Additional Requirements

- Every directory must contain a README.md
- Do not duplicate content across directories
- If content applies to multiple audiences → place in docs/ and reference it
- Do not invent undocumented endpoints or behavior

---

## Phase 3 — Test Planning

Create:

docs/test-strategy.md

Include:

- unit test targets
- integration test targets
- critical user flows
- authentication test cases
- database interaction testing approach
- mocking/stubbing strategy
- fixtures and test data plan
- edge cases and failure modes
- known gaps or uncertainties

---

## Phase 4 — Implementation (Operator-Gated)

Before implementing any changes:

1. Present a summary of the planned implementation:
   - what will be added/modified
   - which files will be touched
   - what tests will be created
   - any assumptions or risks

2. WAIT for explicit operator approval before proceeding.

   Acceptable confirmations:
   - "approve"
   - "proceed"
   - "implement"
   - or equivalent explicit instruction

3. If the operator requests changes:
   - revise the plan
   - re-present it
   - wait again for approval

4. Only after approval:
   - implement tests according to test-strategy.md
   - keep changes small and reviewable

5. After implementation:
   - summarize what was done
   - highlight any deviations from the plan

---

## Output Expectations

- Structured markdown files
- Clear sectioning and headings
- Minimal redundancy
- Explicit assumptions when necessary

---

## Failure Handling

If any of the following occur:

- missing Documentation-Rules.md
- unclear architecture
- ambiguous API behavior

Then:

- proceed with best-effort analysis
- explicitly document uncertainty
- do not guess or invent missing details

