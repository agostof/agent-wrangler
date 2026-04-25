# Documentation Structure Rules

## Directory Overview

| Directory       | Audience              | Purpose                                              |
|-----------------|-----------------------|------------------------------------------------------|
| `docs/`         | Everyone              | Concepts, architecture, design decisions, API ref    |
| `agent-docs/`   | AI agents (+ operators auditing agent assumptions) | Context, constraints, conventions agents must follow |
| `operator-docs/`| Human operators only  | Runbooks, deployment, config, monitoring             |

## Rules

1. Every directory MUST contain a `README.md` that states its audience, purpose, and where to start.
2. The top-level `README.md` MUST orient all three audiences and link to each directory.
3. `docs/` is the canonical source of truth for system design. Do not duplicate content from `docs/` in other directories — reference it instead.
4. `agent-docs/` contains only what an agent needs loaded into context: capabilities, constraints, assumptions, and conventions. It MUST NOT contain operational procedures.
5. `operator-docs/` contains only procedural, human-executed content: runbooks, deployment steps, monitoring, config. It MUST NOT contain content an agent needs.
6. If content is relevant to more than one audience, it belongs in `docs/` with a reference to it from the other directories.
7. Do not create additional top-level documentation directories. If a new audience or concern arises, raise it with a human operator before changing the structure.

## File Placement Checklist

When adding a new file, answer these questions in order:

- Is this a concept, design decision, or API definition? → `docs/`
- Is this an assumption, constraint, or convention an agent must follow? → `agent-docs/`
- Is this a procedure a human executes? → `operator-docs/`
- Does it serve more than one audience? → `docs/`, then reference from the relevant directory


