# Tools Documentation

## Audience

This documentation serves three audiences:
- everyone who needs the canonical design and usage model for the `/tools` indexing scripts
- AI agents that need constraints and conventions for using the scripts correctly
- human operators onboarding into a repository and running the scripts as part of inspection

## Purpose

This directory documents the `/tools/index-*.sh` repository indexing system, including:
- what the scripts do
- what they output
- when to use them
- how agents should use them
- how operators should use them

## Where To Start

- For system design, capabilities, outputs, and example use cases, start in [docs/README.md](/tools/docs/docs/README.md).
- For agent usage conventions and workflow, start in [agent-docs/README.md](/tools/docs/agent-docs/README.md).
- For human-executed onboarding and runbook steps, start in [operator-docs/README.md](/tools/docs/operator-docs/README.md).

## Structure

- `docs/`
  Canonical source of truth for script behavior, outputs, supported languages, and example use cases.
- `agent-docs/`
  Agent-specific workflow, assumptions, and constraints for using the scripts effectively.
- `operator-docs/`
  Human-oriented onboarding and execution runbooks.
