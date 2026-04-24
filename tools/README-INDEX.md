#!/bin/bash
# README-INDEX.md
# Repository Indexing System for LLM Agents

## Overview

These scripts create a multi-format repository index that helps the Agent (Claude Code, or Codex) understand your codebase structure, definitions, and relationships.

**Supported languages:** Python, JavaScript, TypeScript, Bash/Shell

**Output formats:** Text (quick scanning), JSON (structured), Markdown (human-readable)

## Quick Start

```bash
# Run from your project root
./index-repo.sh .claude
```

This creates `.claude/index/` with:
- `text/` - Quick reference text files
- `json/` - Structured data for programmatic access
- `markdown/` - Best for human reading and Claude Code

## Scripts

### `index-repo.sh` (Main Orchestrator)
Runs all indexing subscripts in sequence. Creates the directory structure and coordinates output.

**Usage:**
```bash
./index-repo.sh [output_dir]
```

**Default:** Creates index in `.claude/index/`

---

### `index-files.sh`
Collects all source files with metadata: paths, file types, line counts.

**Output:**
- `text/files.txt` - Simple file listing
- `json/files.json` - File metadata with line counts
- `markdown/files.md` - Categorized by file type

**Best for:** Understanding project size and organization

---

### `index-definitions.sh`
Extracts all function, class, and type definitions with line numbers.

**Patterns matched:**
- Python: `def`, `class`
- JavaScript/TypeScript: `function`, `const`, `class`, `interface`, `type`
- Bash: `function_name() {`
- TypeScript: `interface`, `type`

**Output:**
- `text/definitions.txt` - Quick reference list
- `json/definitions.json` - Structured with file/line info
- `markdown/definitions.md` - Organized by language and type

**Best for:** Finding where something is defined, understanding what exists

---

### `index-imports.sh`
Maps all imports, exports, and dependencies.

**Patterns matched:**
- Python: `import`, `from ... import`
- JavaScript/TypeScript: `import ... from`, `export`
- Bash: `source`, `.` (dot sourcing)

**Output:**
- `text/imports.txt` - Import/export frequency
- `json/imports.json` - List of all imports
- `markdown/imports.md` - Organized by language

**Best for:** Understanding dependencies and how modules connect

---

### `index-architecture.sh`
Maps module structure and project organization.

**Analyzes:**
- Top-level directories
- Python packages (`__init__.py`)
- Configuration files (package.json, pyproject.toml, etc.)
- Build/artifact directories (for exclusion)

**Output:**
- `text/architecture.txt` - Directory tree
- `json/architecture.json` - Structured module list
- `markdown/architecture.md` - Human-readable structure

**Best for:** Understanding project layout and module organization

---

### `index-annotations.sh`
Finds all code annotations and work markers.

**Patterns matched:**
- `TODO`, `FIXME`, `XXX`, `HACK`
- `BUG`, `BROKEN`, `ISSUE`, `DEPRECATED`
- `WARN`, `NOTE`, `IMPORTANT`, `CAUTION`

**Output:**
- `text/annotations.txt` - Quick reference
- `json/annotations.json` - Structured with file/line
- `markdown/annotations.md` - Organized by type

**Best for:** Finding unfinished work and technical debt

---

### `index-summary.sh`
Generates unified summaries and overview files.

**Provides:**
- File count statistics by language
- Navigation guide to all index files
- Usage instructions for Claude Code

**Output:**
- `text/SUMMARY.txt` - Quick overview
- `json/SUMMARY.json` - Metadata about the index itself
- `markdown/SUMMARY.md` - Complete guide with links

---

## Output Structure

```
.claude/
└── index/
    ├── text/
    │   ├── definitions.txt
    │   ├── files.txt
    │   ├── imports.txt
    │   ├── architecture.txt
    │   ├── annotations.txt
    │   └── SUMMARY.txt
    ├── json/
    │   ├── definitions.json
    │   ├── files.json
    │   ├── imports.json
    │   ├── architecture.json
    │   ├── annotations.json
    │   └── SUMMARY.json
    └── markdown/
        ├── definitions.md
        ├── files.md
        ├── imports.md
        ├── architecture.md
        ├── annotations.md
        └── SUMMARY.md
```

## Using with Claude Code

### Method 1: Include in CLAUDE.md (Recommended)

Add to `.claude/CLAUDE.md`:

```markdown
# Project Context

## Index Files
@.claude/index/markdown/definitions.md
@.claude/index/markdown/architecture.md
@.claude/index/markdown/annotations.md
```

Claude will automatically include these when starting a session.

### Method 2: Reference in Queries

When working with Claude, reference the index:

```
"Looking at index/markdown/definitions.md, I see the main 
functions are... Can you help me understand how they interact?"
```

### Method 3: Use in Custom Skills

Build Claude Code skills that parse the JSON indices:

```javascript
// Read and parse definitions.json
const definitions = require('./.claude/index/json/definitions.json');
const pythonFunctions = definitions.definitions.python.functions;
```

## Customization

### Modify Language Support

Edit the pattern arrays in individual scripts:

**In `index-files.sh`:**
```bash
PATTERNS=(
  "*.py"
  "*.js"
  "*.jsx"
  "*.ts"
  "*.tsx"
  "*.sh"
  # Add more patterns here
)
```

### Adjust Filtering

Exclude more directories by modifying the `find` and `rg` commands:

```bash
# In any script, add to exclusions:
! -path '*/some_dir/*' \
! -path '*/another_dir/*'
```

### Change Output Limits

Each script limits results to prevent huge files:

```bash
# In index-definitions.sh
rg "^def\s+(\w+)" -t py | head -100  # Change 100 to your limit
```

### Adjust Annotation Markers

Edit the regex patterns in `index-annotations.sh`:

```bash
# Add more markers
rg "TODO|FIXME|XXX|HACK|URGENT|REFACTOR" --line-number
```

## Performance Notes

- Scripts use `ripgrep` (rg) for fast searching
- Large repos (10k+ files) may take 30-60 seconds
- JSON generation handles up to ~1000 items per category (configurable)
- All scripts respect `.gitignore` automatically

**Performance Tip:** For huge monorepos, limit search depth:

```bash
# In scripts, add:
rg "pattern" --max-depth 5
```

## Troubleshooting

### Scripts fail with "rg not found"

Install ripgrep:
```bash
# macOS
brew install ripgrep

# Linux
cargo install ripgrep

# Or use system package manager
```

### JSON output is incomplete

The scripts limit results to prevent huge files. Increase limits in the scripts:

```bash
# Change head -50 to head -200 in any script
head -50  →  head -200
```

### CLAUDE.md references show errors

Make sure the `.claude/` directory structure is created:

```bash
./index-repo.sh .claude  # This creates it
```

## Regenerating the Index

Run anytime after significant code changes:

```bash
./index-repo.sh .claude
```

Or programmatically:

```bash
(cd /path/to/project && ./index-repo.sh)
```

## File Formats

### Text Format

Simple line-by-line output, best for quick scanning:

```
definitions.txt:
================
file.py:10: def my_function(arg)
file.py:20: class MyClass:
```

### JSON Format

Structured data, best for programmatic access:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "definitions": {
    "python": {
      "functions": [
        {"name": "my_function", "file": "file.py", "line": 10}
      ]
    }
  }
}
```

### Markdown Format

Human-readable with sections and links:

```markdown
## Python

### Functions
- `my_function` (file.py:10)
- `another_func` (file.py:25)

### Classes
- `MyClass` (file.py:20)
```

---

**Created:** $(date)
**For use with:** Claude Code (and claude.ai)
