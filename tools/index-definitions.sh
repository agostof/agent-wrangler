#!/bin/bash
# index-definitions.sh
# Extract all function, class, and key definitions with line numbers

OUTPUT_DIR="${1:-.claude}"

# Generate text format (quick reference)
{
  echo "# Definitions Index"
  echo "Generated: $(date)"
  echo ""
  
  echo "## Python Functions and Classes"
  rg "^(def|class)\s+(\w+)" -t py --line-number --no-heading | head -100
  echo ""
  
  echo "## JavaScript/TypeScript Functions, Classes, and Exports"
  rg "^(export\s+)?(async\s+)?(function|const|class)\s+(\w+)" -t js -t ts --line-number --no-heading | head -100
  echo ""
  
  echo "## Bash Functions"
  rg "^(\w+)\s*\(\)\s*\{" -t sh --line-number --no-heading | head -50
  echo ""
  
  echo "## TypeScript Interfaces and Types"
  rg "^(export\s+)?(interface|type)\s+(\w+)" -t ts --line-number --no-heading | head -100
  
} > "$OUTPUT_DIR/index/text/definitions.txt"

# Generate JSON format (machine-readable with structure)
{
  echo "{"
  echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "definitions": {'
  
  echo '    "python": {'
  echo '      "functions": ['
  rg "^def\s+(\w+)" -t py --line-number --no-heading -o | awk -F: '{print "        {\"name\": \"" $NF "\", \"file\": \"" $1 "\", \"line\": " $2 "}"}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '      ],'
  echo '      "classes": ['
  rg "^class\s+(\w+)" -t py --line-number --no-heading -o | awk -F: '{print "        {\"name\": \"" $NF "\", \"file\": \"" $1 "\", \"line\": " $2 "}"}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '      ]'
  echo '    },'
  
  echo '    "javascript_typescript": {'
  echo '      "functions": ['
  rg "^(export\s+)?(async\s+)?function\s+(\w+)" -t js -t ts --line-number --no-heading -o | head -50 | awk '{print "        \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '      ],'
  echo '      "classes": ['
  rg "^(export\s+)?class\s+(\w+)" -t js -t ts --line-number --no-heading -o | head -50 | awk '{print "        \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '      ],'
  echo '      "types": ['
  rg "^(export\s+)?(type|interface)\s+(\w+)" -t ts --line-number --no-heading -o | head -50 | awk '{print "        \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '      ]'
  echo '    },'
  
  echo '    "bash": {'
  echo '      "functions": ['
  rg "^(\w+)\s*\(\)\s*\{" -t sh --line-number --no-heading -o | head -50 | awk '{print "        \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '      ]'
  echo '    }'
  echo '  }'
  echo "}"
} > "$OUTPUT_DIR/index/json/definitions.json"

# Generate Markdown format (human-readable summary)
{
  echo "# Definitions and Symbols"
  echo ""
  echo "**Generated:** $(date)"
  echo ""
  echo "Quick reference to all major function, class, and type definitions in the codebase."
  echo ""
  
  echo "## Python"
  echo ""
  echo "### Classes"
  echo ""
  echo "\`\`\`"
  rg "^class\s+(\w+)" -t py --line-number | head -30
  echo "\`\`\`"
  echo ""
  
  echo "### Functions"
  echo ""
  echo "\`\`\`"
  rg "^def\s+(\w+)" -t py --line-number | head -30
  echo "\`\`\`"
  echo ""
  
  echo "## JavaScript / TypeScript"
  echo ""
  echo "### Classes"
  echo ""
  echo "\`\`\`"
  rg "^(export\s+)?class\s+(\w+)" -t js -t ts --line-number | head -30
  echo "\`\`\`"
  echo ""
  
  echo "### Functions"
  echo ""
  echo "\`\`\`"
  rg "^(export\s+)?(async\s+)?function\s+(\w+)" -t js -t ts --line-number | head -30
  echo "\`\`\`"
  echo ""
  
  echo "### Types & Interfaces (TypeScript)"
  echo ""
  echo "\`\`\`"
  rg "^(export\s+)?(type|interface)\s+(\w+)" -t ts --line-number | head -30
  echo "\`\`\`"
  echo ""
  
  echo "## Bash"
  echo ""
  echo "### Functions"
  echo ""
  echo "\`\`\`"
  rg "^(\w+)\s*\(\)\s*\{" -t sh --line-number | head -30
  echo "\`\`\`"
  
} > "$OUTPUT_DIR/index/markdown/definitions.md"
