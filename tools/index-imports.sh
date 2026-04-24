#!/bin/bash
# index-imports.sh
# Extract imports, exports, and dependency information

OUTPUT_DIR="${1:-.claude}"

# Generate text format (simple mapping)
{
  echo "# Imports and Exports Index"
  echo "Generated: $(date)"
  echo ""
  
  echo "## Python Imports"
  rg "^(import|from)\s+[\w.]+" -t py --no-heading | sort | uniq -c | sort -rn | head -50
  echo ""
  
  echo "## JavaScript/TypeScript Imports"
  rg "^import\s+.*from\s+['\"]" -t js -t ts --no-heading | sort | uniq -c | sort -rn | head -50
  echo ""
  
  echo "## TypeScript/JavaScript Exports"
  rg "^export\s+(const|function|class|interface|type)" -t js -t ts --line-number --no-heading | head -50
  echo ""
  
  echo "## Bash Source Commands"
  rg '^\s*source\s+|^\s*\.\s+' -t sh --no-heading | sort | uniq -c | sort -rn | head -30
  
} > "$OUTPUT_DIR/index/text/imports.txt"

# Generate JSON format
{
  echo "{"
  echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "imports_and_exports": {'
  
  echo '    "python_imports": ['
  rg "^import\s+[\w.]+" -t py --no-heading -o | sort | uniq | awk '{print "      \"" $0 "\""}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'
  
  echo '    "js_ts_imports": ['
  rg "^import\s+.*from\s+['\"]" -t js -t ts --no-heading -o | sort | uniq | awk '{print "      \"" $0 "\""}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'
  
  echo '    "exports": ['
  rg "^export\s+" -t js -t ts --no-heading -o | sort | uniq | awk '{print "      \"" $0 "\""}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ]'
  
  echo '  }'
  echo "}"
} > "$OUTPUT_DIR/index/json/imports.json"

# Generate Markdown format
{
  echo "# Imports & Exports"
  echo ""
  echo "**Generated:** $(date)"
  echo ""
  echo "## Python Dependencies"
  echo ""
  
  echo "### Most Common Imports"
  echo ""
  echo "\`\`\`"
  rg "^import\s+[\w.]+" -t py --no-heading | sort | uniq -c | sort -rn | head -20
  echo "\`\`\`"
  echo ""
  
  echo "### From Imports"
  echo ""
  echo "\`\`\`"
  rg "^from\s+[\w.]+\s+import" -t py --no-heading | sort | uniq -c | sort -rn | head -20
  echo "\`\`\`"
  echo ""
  
  echo "## JavaScript/TypeScript Dependencies"
  echo ""
  echo "### Imports"
  echo ""
  echo "\`\`\`"
  rg "^import\s+.*from\s+['\"]" -t js -t ts --no-heading | sort | uniq -c | sort -rn | head -25
  echo "\`\`\`"
  echo ""
  
  echo "### Exports"
  echo ""
  echo "\`\`\`"
  rg "^export\s+" -t js -t ts --no-heading | sort | uniq -c | sort -rn | head -25
  echo "\`\`\`"
  echo ""
  
  echo "## Bash Sourcing"
  echo ""
  echo "\`\`\`"
  rg '^\s*(source|\.)\s+' -t sh --no-heading | sort | uniq -c | sort -rn | head -20
  echo "\`\`\`"
  
} > "$OUTPUT_DIR/index/markdown/imports.md"
