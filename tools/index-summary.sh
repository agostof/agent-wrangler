#!/bin/bash
# index-summary.sh
# Generate unified summaries and quick-reference guides

OUTPUT_DIR="${1:-.claude}"

# Generate text format (unified reference)
{
  echo "# Complete Index Summary"
  echo "Generated: $(date)"
  echo ""
  
  py_count=$(rg --files -g "*.py" | wc -l)
  js_count=$(rg --files -g "*.js" -g "*.jsx" | wc -l)
  ts_count=$(rg --files -g "*.ts" -g "*.tsx" | wc -l)
  sh_count=$(rg --files -g "*.sh" -g "*.bash" | wc -l)
  
  echo "## Project Statistics"
  echo ""
  echo "Python files:    $py_count"
  echo "JavaScript files: $js_count"
  echo "TypeScript files: $ts_count"
  echo "Bash files:      $sh_count"
  echo ""
  
  echo "## Quick Navigation"
  echo ""
  echo "1. DEFINITIONS (index/markdown/definitions.md)"
  echo "   - All functions, classes, types, and interfaces"
  echo ""
  echo "2. FILES (index/markdown/files.md)"
  echo "   - Complete file listing by type"
  echo ""
  echo "3. IMPORTS (index/markdown/imports.md)"
  echo "   - Dependencies and external references"
  echo ""
  echo "4. ARCHITECTURE (index/markdown/architecture.md)"
  echo "   - Module structure and organization"
  echo ""
  echo "5. ANNOTATIONS (index/markdown/annotations.md)"
  echo "   - TODOs, FIXMEs, HACKs, and work items"
  echo ""
  
  echo "## For Claude Code"
  echo ""
  echo "All indices are available in three formats:"
  echo "- .txt files for quick scanning"
  echo "- .json files for structured parsing"
  echo "- .md files for human reading"
  echo ""
  echo "Include in CLAUDE.md with:"
  echo "@.claude/index/markdown/definitions.md"
  echo "@.claude/index/markdown/architecture.md"
  echo "@.claude/index/markdown/annotations.md"
  
} > "$OUTPUT_DIR/index/text/SUMMARY.txt"

# Generate JSON format (comprehensive metadata)
{
  echo "{"
  echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "summary": {'
  
  py_count=$(rg --files -g "*.py" | wc -l)
  js_count=$(rg --files -g "*.js" -g "*.jsx" | wc -l)
  ts_count=$(rg --files -g "*.ts" -g "*.tsx" | wc -l)
  sh_count=$(rg --files -g "*.sh" -g "*.bash" | wc -l)
  
  py_lines=$(rg --files -g "*.py" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
  js_lines=$(rg --files -g "*.js" -g "*.jsx" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
  ts_lines=$(rg --files -g "*.ts" -g "*.tsx" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
  sh_lines=$(rg --files -g "*.sh" -g "*.bash" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
  
  echo '    "file_counts": {'
  echo '      "python": '$py_count','
  echo '      "javascript": '$js_count','
  echo '      "typescript": '$ts_count','
  echo '      "bash": '$sh_count
  echo '    },'
  echo '    "line_counts": {'
  echo '      "python": '$py_lines','
  echo '      "javascript": '$js_lines','
  echo '      "typescript": '$ts_lines','
  echo '      "bash": '$sh_lines
  echo '    },'
  echo '    "index_files": ['
  echo '      "index/text/definitions.txt",'
  echo '      "index/text/files.txt",'
  echo '      "index/text/imports.txt",'
  echo '      "index/text/architecture.txt",'
  echo '      "index/text/annotations.txt",'
  echo '      "index/json/definitions.json",'
  echo '      "index/json/files.json",'
  echo '      "index/json/imports.json",'
  echo '      "index/json/architecture.json",'
  echo '      "index/json/annotations.json",'
  echo '      "index/markdown/definitions.md",'
  echo '      "index/markdown/files.md",'
  echo '      "index/markdown/imports.md",'
  echo '      "index/markdown/architecture.md",'
  echo '      "index/markdown/annotations.md"'
  echo '    ]'
  
  echo '  }'
  echo "}"
} > "$OUTPUT_DIR/index/json/SUMMARY.json"

# Generate Markdown format (human-friendly overview)
{
  echo "# Repository Index - Summary"
  echo ""
  echo "**Generated:** $(date)"
  echo ""
  
  py_count=$(rg --files -g "*.py" 2>/dev/null | wc -l)
  js_count=$(rg --files -g "*.js" -g "*.jsx" 2>/dev/null | wc -l)
  ts_count=$(rg --files -g "*.ts" -g "*.tsx" 2>/dev/null | wc -l)
  sh_count=$(rg --files -g "*.sh" -g "*.bash" 2>/dev/null | wc -l)
  
  echo "## Project Overview"
  echo ""
  echo "| Language | Files |"
  echo "|----------|-------|"
  echo "| Python | $py_count |"
  echo "| JavaScript | $js_count |"
  echo "| TypeScript | $ts_count |"
  echo "| Bash/Shell | $sh_count |"
  echo ""
  
  echo "## Index Files Available"
  echo ""
  echo "### Markdown Format (Best for reading)"
  echo ""
  echo "- **[definitions.md](markdown/definitions.md)** - All functions, classes, types"
  echo "- **[files.md](markdown/files.md)** - Complete file listing by type"
  echo "- **[imports.md](markdown/imports.md)** - Dependencies and imports"
  echo "- **[architecture.md](markdown/architecture.md)** - Module structure"
  echo "- **[annotations.md](markdown/annotations.md)** - TODOs and work items"
  echo ""
  
  echo "### JSON Format (Best for parsing)"
  echo ""
  echo "- **definitions.json** - Structured definition catalog"
  echo "- **files.json** - File metadata with line counts"
  echo "- **imports.json** - Dependency catalog"
  echo "- **architecture.json** - Module and package structure"
  echo "- **annotations.json** - Coded items with locations"
  echo "- **SUMMARY.json** - Index statistics"
  echo ""
  
  echo "### Text Format (Quick reference)"
  echo ""
  echo "- **definitions.txt**"
  echo "- **files.txt**"
  echo "- **imports.txt**"
  echo "- **architecture.txt**"
  echo "- **annotations.txt**"
  echo "- **SUMMARY.txt**"
  echo ""
  
  echo "## Using with Claude Code"
  echo ""
  echo "### Option 1: Include in CLAUDE.md"
  echo ""
  echo "Add to your \`.claude/CLAUDE.md\`:"
  echo ""
  echo "\`\`\`markdown"
  echo "# Project Index"
  echo ""
  echo "@.claude/index/markdown/definitions.md"
  echo "@.claude/index/markdown/architecture.md"
  echo "@.claude/index/markdown/annotations.md"
  echo "\`\`\`"
  echo ""
  echo "### Option 2: Reference in queries"
  echo ""
  echo "When you need to understand the codebase, Claude can read:"
  echo "- \`index/markdown/\` - for human-readable summaries"
  echo "- \`index/json/\` - for structured data lookup"
  echo ""
  echo "### Option 3: Use in custom skills"
  echo ""
  echo "Reference the JSON files when building Claude Code skills that need"
  echo "to understand project structure or find specific definitions."
  echo ""
  
  echo "## Regenerating the Index"
  echo ""
  echo "Run any time the codebase changes:"
  echo ""
  echo "\`\`\`bash"
  echo "./index-repo.sh .claude"
  echo "\`\`\`"
  echo ""
  
  echo "---"
  echo ""
  echo "**Index generated by:** \`index-repo.sh\` and helper scripts"
  
} > "$OUTPUT_DIR/index/markdown/SUMMARY.md"
