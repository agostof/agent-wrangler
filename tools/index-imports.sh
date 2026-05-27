#!/bin/bash
# index-imports.sh
# Extract imports, exports, and dependency information

OUTPUT_DIR="${1:-.claude}"
shopt -s expand_aliases
alias rg='rg --no-messages'

{
  echo "# Imports and Exports Index"
  echo "Generated: $(date)"
  echo ""

  echo "## Python Imports"
  rg "^(import|from)\s+[\w.]+" -t py --no-heading | sort | uniq -c | sort -rn | head -50
  echo ""

  echo "## Java Package Declarations"
  rg "^package\s+[A-Za-z0-9_.]+;" -g "*.java" --no-heading | sort | uniq -c | sort -rn | head -50
  echo ""

  echo "## Java Imports"
  rg "^import\s+(static\s+)?[A-Za-z0-9_.*]+;" -g "*.java" --no-heading | sort | uniq -c | sort -rn | head -80
  echo ""

  echo "## Java Build Dependencies"
  rg "<groupId>|<artifactId>|implementation|api|compileOnly|runtimeOnly|testImplementation|testRuntimeOnly" pom.xml build.gradle build.gradle.kts --line-number --no-heading 2>/dev/null | head -120
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

{
  echo "{"
  echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "imports_and_exports": {'

  echo '    "python_imports": ['
  rg "^import\s+[\w.]+" -t py --no-heading -o | sort | uniq | awk '{print "      \"" $0 "\""}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'

  echo '    "java_packages": ['
  rg "^package\s+[A-Za-z0-9_.]+;" -g "*.java" --no-heading -o | sort | uniq | awk '{print "      \"" $0 "\""}' | head -80 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'

  echo '    "java_imports": ['
  rg "^import\s+(static\s+)?[A-Za-z0-9_.*]+;" -g "*.java" --no-heading -o | sort | uniq | awk '{print "      \"" $0 "\""}' | head -120 | paste -sd ',' - | sed 's/,$//'
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

{
  echo "# Imports & Dependencies"
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

  echo "## Java Dependencies"
  echo ""
  echo "### Package Declarations"
  echo ""
  echo "\`\`\`"
  rg "^package\s+[A-Za-z0-9_.]+;" -g "*.java" --line-number | head -40
  echo "\`\`\`"
  echo ""

  echo "### Imports"
  echo ""
  echo "\`\`\`"
  rg "^import\s+(static\s+)?[A-Za-z0-9_.*]+;" -g "*.java" --line-number | head -80
  echo "\`\`\`"
  echo ""

  echo "### Maven / Gradle Dependency Declarations"
  echo ""
  echo "\`\`\`"
  rg "<groupId>|<artifactId>|implementation|api|compileOnly|runtimeOnly|testImplementation|testRuntimeOnly" pom.xml build.gradle build.gradle.kts --line-number 2>/dev/null | head -100
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
