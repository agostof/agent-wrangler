# Repository Onboarding Runbook

## Purpose

This runbook describes how a human operator should run the `/tools` indexing scripts during repository onboarding.

For canonical script behavior and output definitions, see [indexing-system.md](/tools/docs/docs/indexing-system.md).

## Preconditions

- You are in the repository root.
- `bash` is installed.
- `rg` is installed.
- The repository is readable from the current environment.

## Standard Operator Workflow

### Option 1: Create a persistent onboarding bundle

Run:

```bash
bash /tools/index-repo.sh .onboarding
```

This creates:

```text
.onboarding/index/
```

Recommended review order:

1. `.onboarding/index/markdown/SUMMARY.md`
2. `.onboarding/index/markdown/architecture.md`
3. `.onboarding/index/markdown/definitions.md`
4. `.onboarding/index/markdown/imports.md`
5. `.onboarding/index/markdown/annotations.md`

Use this option when:
- you want durable onboarding artifacts
- you want to share the output with another human
- you want a stable snapshot before changes begin

### Option 2: Create an agent-oriented working bundle

Run:

```bash
bash /tools/index-repo.sh .claude
```

Use this option when:
- an agent will use the output immediately
- the repository is being analyzed interactively

## Example Operator Use Cases

### New service onboarding

Goal:
- understand a newly inherited Java service

Run:

```bash
bash /tools/index-repo.sh .onboarding
```

Then review:
- architecture for source roots and build system
- definitions for major classes
- imports for frameworks and dependencies

### Pre-migration assessment

Goal:
- understand dependency and package layout before moving frameworks or Java versions

Run:

```bash
bash /tools/index-repo.sh .onboarding
sed -n '1,260p' .onboarding/index/markdown/imports.md
```

Then confirm important findings in:
- `pom.xml`
- `build.gradle`
- `build.gradle.kts`

### Risk scan before assignment

Goal:
- identify obvious debt markers before handing the repo to an engineer or agent

Run:

```bash
bash /tools/index-repo.sh .onboarding
sed -n '1,220p' .onboarding/index/markdown/annotations.md
```

## What To Expect From Output

- `stdout` shows progress and a final file listing
- the actual useful output is written to files
- Markdown is the best format for direct reading
- JSON is best when another tool or agent will parse the results
- text files are useful for quick shell-side review

## Troubleshooting

### The index seems empty

Check:

```bash
pwd
rg --files -g '*.java' | head
find src -maxdepth 3 -type d | sort
```

Possible causes:
- you are not at the repository root
- `rg` is missing
- the repo does not use expected source layouts

### The Java method list looks noisy

That output is heuristic. Use it as a pointer, then inspect the real source files directly.

### Dependency output looks incomplete

Read the build files directly. The index summarizes dependency declarations but does not resolve the full dependency graph.

## Operator Notes

- Keep the generated output directory if you want a reusable onboarding artifact.
- Re-run the index after major repository restructuring if the existing snapshot is stale.
