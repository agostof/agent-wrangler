# Agent Workflow For Java Repo Indexing

## Scope

This document tells an agent how to use the `/tools` repository indexing scripts on Java repositories.

For the canonical tool behavior and output model, see [indexing-system.md](/tools/docs/docs/indexing-system.md).

## When To Use The Index

Use the index near the start of a task when:
- the repository is unfamiliar
- the user asked for analysis or documentation
- the task spans multiple packages or modules
- the agent needs a fast map before opening many files

Do not use the index as a substitute for direct source inspection when:
- the task depends on exact Java semantics
- the user asked for precise behavior explanation
- an implementation or bug hinges on one code path

## Agent Workflow

1. Confirm you are at the repository root.
2. Run:

```bash
bash /tools/index-repo.sh .claude
```

3. Read:
- `.claude/index/markdown/SUMMARY.md`
- `.claude/index/markdown/architecture.md`
- `.claude/index/markdown/definitions.md`
- `.claude/index/markdown/imports.md`
- `.claude/index/markdown/annotations.md` when relevant

4. Convert the index into a targeted file-reading plan.
5. Open real source files and validate important claims before reporting them.

## Agent Rules

- Treat the index as a navigation aid, not ground truth.
- Cite actual repository files in user-facing analysis, not only generated index files.
- If the repo changes materially during the task, regenerate the index if the map is stale.
- Prefer the Markdown index files for fast orientation and the JSON files only when structured parsing is needed.
- Use the text files only for quick scanning or shell-side grep workflows.

## Common Follow-Up Commands

```bash
rg --files -g '*.java'
rg -n 'class |interface |enum |record ' src/main/java
rg -n '^import ' src/main/java
find src -maxdepth 4 -type d | sort
```

When validation is needed:

```bash
mvn test -q
```

Or the equivalent Gradle command if the repo is Gradle-based.

## Failure Modes To Remember

- Method detection is heuristic.
- Import summaries are not a resolved dependency graph.
- Build directories are intentionally excluded.
- Generated code may be absent from the index even if it matters at runtime.

## Relation To The Skill

If the `java-repo-indexing` skill is installed, this document is the human-readable process companion for the same workflow.
