#!/bin/bash
# index-definitions.sh
# Extract all function, class, and key definitions with line numbers

OUTPUT_DIR="${1:-.claude}"
shopt -s expand_aliases
alias rg='rg --no-messages'

{
  echo "# Definitions Index"
  echo "Generated: $(date)"
  echo ""

  echo "## Python Functions and Classes"
  rg "^(def|class)\s+(\w+)" -t py --line-number --no-heading | head -100
  echo ""

  echo "## Java Classes, Interfaces, Enums, and Records"
  rg "^[[:space:]]*(public|protected|private|abstract|final|sealed|non-sealed|static|\s)*[[:space:]]*(class|interface|enum|record)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*" -g "*.java" --line-number --no-heading | head -150
  echo ""

  echo "## Java Methods"
  rg "^[[:space:]]*(public|protected|private|static|final|synchronized|abstract|default|native|strictfp|\s)+[[:space:]<>\\[\\],A-Za-z0-9_?]+[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\\([^;]*\\)[[:space:]]*(throws[[:space:]]+[A-Za-z0-9_.,[:space:]]+)?[[:space:]]*\\{" -g "*.java" --line-number --no-heading | head -200
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

  echo '    "java": {'
  echo '      "types": ['
  rg "^[[:space:]]*(public|protected|private|abstract|final|sealed|non-sealed|static|\s)*[[:space:]]*(class|interface|enum|record)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*" -g "*.java" --line-number --no-heading | head -100 | awk -F: '{print "        {\"file\": \"" $1 "\", \"line\": " $2 ", \"text\": \"" $3 "\"}"}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '      ],'
  echo '      "methods": ['
  rg "^[[:space:]]*(public|protected|private|static|final|synchronized|abstract|default|native|strictfp|\s)+[[:space:]<>\\[\\],A-Za-z0-9_?]+[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\\([^;]*\\)[[:space:]]*(throws[[:space:]]+[A-Za-z0-9_.,[:space:]]+)?[[:space:]]*\\{" -g "*.java" --line-number --no-heading | head -150 | awk -F: '{print "        {\"file\": \"" $1 "\", \"line\": " $2 ", \"text\": \"" $3 "\"}"}' | paste -sd ',' - | sed 's/,$//'
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

{
  echo "# Definitions and Symbols"
  echo ""
  echo "**Generated:** $(date)"
  echo ""
  echo "Quick reference to major function, class, type, and method definitions in the codebase."
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

  echo "## Java"
  echo ""
  echo "### Types"
  echo ""
  echo "\`\`\`"
  rg "^[[:space:]]*(public|protected|private|abstract|final|sealed|non-sealed|static|\s)*[[:space:]]*(class|interface|enum|record)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*" -g "*.java" --line-number | head -50
  echo "\`\`\`"
  echo ""

  echo "### Methods"
  echo ""
  echo "\`\`\`"
  rg "^[[:space:]]*(public|protected|private|static|final|synchronized|abstract|default|native|strictfp|\s)+[[:space:]<>\\[\\],A-Za-z0-9_?]+[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\\([^;]*\\)[[:space:]]*(throws[[:space:]]+[A-Za-z0-9_.,[:space:]]+)?[[:space:]]*\\{" -g "*.java" --line-number | head -60
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
