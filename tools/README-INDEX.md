# README-INDEX.md
# Repository Indexing System for LLM Agents

## Overview

These scripts create a multi-format repository index that helps an agent understand
codebase structure, definitions, dependencies, and work markers.

**Supported languages:** Python, Java, JavaScript, TypeScript, Bash/Shell

**Output formats:** Text (quick scanning), JSON (structured), Markdown (human-readable)

## Quick Start

```bash
# Run from your project root
bash /tools/index-repo.sh .claude
```

This creates `.claude/index/` with:
- `text/` - Quick reference text files
- `json/` - Structured data for programmatic access
- `markdown/` - Readable summaries for humans and agents

## Scripts

### `index-repo.sh`
Runs all indexing subscripts in sequence. Creates the directory structure and coordinates output.

**Usage:**
```bash
bash /tools/index-repo.sh [output_dir]
```

**Default:** Creates index in `.claude/index/`

### `index-files.sh`
Collects source files with metadata: paths, file types, line counts.

Java support:
- `*.java`
- Maven and Gradle wrapper/build files are surfaced in architecture and summary outputs

### `index-definitions.sh`
Extracts major definitions with line numbers.

Java support includes:
- `class`
- `interface`
- `enum`
- `record`
- method-like declarations

This is heuristic indexing, not full parsing. Treat results as navigation aids rather than a formal symbol table.

### `index-imports.sh`
Maps imports and dependency declarations.

Java support includes:
- `package ...;`
- `import ...;`
- build dependencies from `pom.xml`, `build.gradle`, and `build.gradle.kts`

### `index-architecture.sh`
Maps module structure and project organization.

Java support includes:
- Maven and Gradle config files
- `src/main/java`, `src/test/java`, and `src/*/resources`
- package trees under Java source roots

### `index-annotations.sh`
Finds `TODO`, `FIXME`, `XXX`, `HACK`, and similar work markers across any source files ripgrep can see.

### `index-summary.sh`
Generates unified language counts and a navigation guide to the index files.

## Java Notes

- For Maven repos, run from the repository root so `pom.xml` and `src/` layout are visible.
- For Gradle repos, run from the repository root so `settings.gradle*` and `build.gradle*` are visible.
- The scripts are intentionally regex-driven and fast. They do not replace a Java parser or language server.

## Output Structure

```text
.claude/
└── index/
    ├── text/
    ├── json/
    └── markdown/
```

## When To Use

Use these scripts when an agent needs:
- a fast repository inventory
- a rough definition map
- a dependency overview
- a quick architecture sketch
- a debt marker scan

Do not rely on them alone when:
- exact Java symbol resolution matters
- overloaded methods or nested classes must be distinguished precisely
- generated sources dominate the repo and need special filtering

## Customization

To add languages or patterns, edit the pattern arrays and `rg` expressions in the individual scripts.

Common Java adjustments:
- add extra exclusions for generated code directories
- widen Gradle or Maven dependency patterns
- tighten method detection if a repo has too many false positives
