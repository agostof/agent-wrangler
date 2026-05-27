# Repository Indexing System

## Purpose

The `/tools/index-*.sh` scripts generate a fast repository index that helps both agents and human operators understand a codebase before deeper manual inspection.

The system is designed to:
- inventory source files
- surface major definitions
- summarize imports and dependencies
- sketch architecture and source layout
- highlight TODO and FIXME markers

## Supported Languages

The current scripts support:
- Python
- Java
- JavaScript
- TypeScript
- Bash and shell

Java support includes:
- `*.java` file indexing
- class, interface, enum, and record detection
- method-like declaration detection
- `package` and `import` scanning
- Maven and Gradle configuration discovery
- Java source-root detection

## Main Entry Point

Run the full index from a repository root:

```bash
bash /tools/index-repo.sh .claude
```

This is the main orchestration script. It creates the output tree, runs all child scripts, and prints progress and a final file listing to `stdout`.

## Output Model

The scripts are not `stdout`-only. They produce persistent file output.

### Standard output

`stdout` is used for:
- progress messages
- stage numbers
- final file listing

### File output

The actual index is written under the directory you pass to `index-repo.sh`.

Example:

```bash
bash /tools/index-repo.sh .claude
```

Produces:

```text
.claude/index/
  text/
  json/
  markdown/
```

Files generated:

- `text/definitions.txt`
- `text/files.txt`
- `text/imports.txt`
- `text/architecture.txt`
- `text/annotations.txt`
- `text/SUMMARY.txt`
- `json/definitions.json`
- `json/files.json`
- `json/imports.json`
- `json/architecture.json`
- `json/annotations.json`
- `json/SUMMARY.json`
- `markdown/definitions.md`
- `markdown/files.md`
- `markdown/imports.md`
- `markdown/architecture.md`
- `markdown/annotations.md`
- `markdown/SUMMARY.md`

This makes the system usable for:
- one-off agent analysis
- repeatable repository onboarding
- human-readable handoff artifacts
- local documentation snapshots

## Script Roles

### `index-repo.sh`

The orchestrator:
- creates the output directories
- runs all child index scripts
- prints execution progress

### `index-files.sh`

Builds a file inventory by language and directory shape.

Use it to answer:
- how large is the codebase
- which languages are present
- where the source files are

### `index-definitions.sh`

Builds a lightweight symbol map.

Java-specific output includes:
- classes
- interfaces
- enums
- records
- method-like declarations

Use it to answer:
- where are the main types
- where is likely business logic
- which files should be opened first

### `index-imports.sh`

Builds a dependency and package map.

Java-specific output includes:
- `package ...;`
- `import ...;`
- common Maven and Gradle dependency declarations

Use it to answer:
- which frameworks dominate the repo
- how internal packages are organized
- which build dependencies are declared

### `index-architecture.sh`

Builds a module and layout overview.

Java-specific output includes:
- `src/main/java`
- `src/test/java`
- `src/main/resources`
- `src/test/resources`
- `pom.xml`
- `build.gradle`
- `build.gradle.kts`
- `settings.gradle*`

Use it to answer:
- is this Maven or Gradle
- where are source roots
- whether tests exist
- whether the repo looks single-module or multi-module

### `index-annotations.sh`

Finds work markers such as:
- `TODO`
- `FIXME`
- `XXX`
- `HACK`
- `DEPRECATED`

Use it to answer:
- where known debt is
- whether there are incomplete areas
- whether risky work zones are already marked

### `index-summary.sh`

Builds a compact navigation entrypoint and language counts.

Use it to answer:
- which language dominates the repository
- which generated index files should be read first

## Recommended Reading Order

After generating an index, the usual reading order is:

1. `markdown/SUMMARY.md`
2. `markdown/architecture.md`
3. `markdown/definitions.md`
4. `markdown/imports.md`
5. `markdown/annotations.md`
6. real source files referenced by the index

## Example Use Cases

### Example 1: Agent starting a repo analysis

An agent is asked to analyze a Java repository and produce architecture notes.

Recommended use:

```bash
bash /tools/index-repo.sh .claude
sed -n '1,220p' .claude/index/markdown/SUMMARY.md
sed -n '1,260p' .claude/index/markdown/architecture.md
sed -n '1,260p' .claude/index/markdown/definitions.md
```

Outcome:
- the agent quickly identifies source roots and package layout
- the agent uses the symbol map to choose which Java files to inspect directly

### Example 2: Human operator onboarding into a new repo

A human operator wants persistent onboarding artifacts for a new Java service.

Recommended use:

```bash
bash /tools/index-repo.sh .onboarding
```

Outcome:
- a file-based onboarding bundle is created under `.onboarding/index/`
- the operator can read Markdown files directly or share them with others

### Example 3: Pre-refactor dependency mapping

An engineer wants to understand framework use before a large refactor.

Recommended use:

```bash
bash /tools/index-repo.sh .claude
sed -n '1,260p' .claude/index/markdown/imports.md
sed -n '1,260p' pom.xml
```

Outcome:
- the index shows major Java imports and declared dependencies
- the engineer confirms important details against build files

### Example 4: Code review or risk scan

An agent or operator wants to locate unfinished or risky areas before changes.

Recommended use:

```bash
bash /tools/index-repo.sh .claude
sed -n '1,220p' .claude/index/markdown/annotations.md
```

Outcome:
- known debt markers are surfaced early
- follow-up file inspection can focus on high-risk areas

## Strengths

- fast
- simple to run
- file-based outputs are easy to keep or share
- useful for both agents and human operators
- works well as a first-pass map before deeper reading

## Limitations

These tools are regex-driven, not parser-driven.

Do not over-trust them for:
- exact Java symbol resolution
- overloaded method disambiguation
- annotation processor output understanding
- generated source analysis
- full dependency graph resolution

Important claims should always be confirmed against actual source files and build files.

## Validation Expectations

The indexing scripts are intended as navigation and orientation tools.

For Java repositories, important follow-up validation usually includes:
- opening the actual `.java` files
- reading `pom.xml` or Gradle build files directly
- running `mvn test -q` or the appropriate Gradle validation command when needed
