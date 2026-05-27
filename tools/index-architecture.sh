#!/bin/bash
# index-architecture.sh
# Map module structure and architectural relationships

OUTPUT_DIR="${1:-.claude}"

{
  echo "# Architecture Index"
  echo "Generated: $(date)"
  echo ""

  echo "## Directory Tree (Source Files Only)"
  find . -type f \( -name "*.py" -o -name "*.java" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) \
    ! -path '*/node_modules/*' \
    ! -path '*/.git/*' \
    ! -path '*/.*' \
    ! -path '*/build/*' \
    ! -path '*/dist/*' \
    ! -path '*/target/*' \
    ! -path '*/__pycache__/*' \
    ! -path '*/.venv/*' \
    ! -path '*/venv/*' | sort | head -150

  echo ""
  echo "## Java Source Roots"
  find . -type d \( -path "*/src/main/java" -o -path "*/src/test/java" -o -path "*/src/main/resources" -o -path "*/src/test/resources" \) | sort

  echo ""
  echo "## Java Package Structure"
  find . -type f -name "*.java" \
    ! -path '*/target/*' \
    ! -path '*/build/*' | sed -n 's|^\./||; s|/[^/]*$||; p' | sort -u | head -120

  echo ""
  echo "## Python Module Structure (__init__.py files)"
  find . -name "__init__.py" ! -path '*/.*' ! -path '*/build/*' ! -path '*/dist/*' | sort

  echo ""
  echo "## Package Configuration Files"
  find . -maxdepth 2 \( \
    -name "package.json" \
    -o -name "pyproject.toml" \
    -o -name "setup.py" \
    -o -name "requirements.txt" \
    -o -name "Dockerfile" \
    -o -name "pom.xml" \
    -o -name "build.gradle" \
    -o -name "build.gradle.kts" \
    -o -name "settings.gradle" \
    -o -name "settings.gradle.kts" \
    -o -name "gradle.properties" \
    -o -name "mvnw" \
    -o -name "mvnw.cmd" \
    -o -name "gradlew" \
    -o -name "gradlew.bat" \
  \) 2>/dev/null | sort
} > "$OUTPUT_DIR/index/text/architecture.txt"

{
  echo "{"
  echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "architecture": {'
  echo '    "main_directories": ['

  find . -maxdepth 1 -type d ! -name '.' ! -name '.*' -print | sed 's|^\./||' | awk '{print "      \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'

  echo '    "config_files": ['
  find . -maxdepth 2 \( \
    -name "package.json" \
    -o -name "pyproject.toml" \
    -o -name "setup.py" \
    -o -name "requirements.txt" \
    -o -name "pom.xml" \
    -o -name "build.gradle" \
    -o -name "build.gradle.kts" \
    -o -name "settings.gradle" \
    -o -name "settings.gradle.kts" \
    -o -name "gradle.properties" \
  \) -type f 2>/dev/null | awk '{print "      \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'

  echo '    "python_packages": ['
  find . -name "__init__.py" ! -path '*/.*' ! -path '*/build/*' ! -path '*/dist/*' | sed 's|__init__.py||' | sort | awk '{print "      \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'

  echo '    "java_source_roots": ['
  find . -type d \( -path "*/src/main/java" -o -path "*/src/test/java" -o -path "*/src/main/resources" -o -path "*/src/test/resources" \) | sort | awk '{print "      \"" $0 "\""}' | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ]'

  echo '  }'
  echo "}"
} > "$OUTPUT_DIR/index/json/architecture.json"

{
  echo "# Architecture & Module Structure"
  echo ""
  echo "**Generated:** $(date)"
  echo ""

  echo "## Top-Level Directories"
  echo ""
  find . -maxdepth 1 -type d ! -name '.' ! -name '.*' -exec sh -c 'echo "- **{}** ($(find "$1" -type f \( -name "*.py" -o -name "*.java" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) | wc -l) source files)"' _ {} \; | sort
  echo ""

  echo "## Java Source Roots"
  echo ""
  echo "\`\`\`"
  find . -type d \( -path "*/src/main/java" -o -path "*/src/test/java" -o -path "*/src/main/resources" -o -path "*/src/test/resources" \) | sort
  echo "\`\`\`"
  echo ""

  echo "## Java Package Directories"
  echo ""
  echo "\`\`\`"
  find . -type f -name "*.java" ! -path '*/target/*' ! -path '*/build/*' | sed -n 's|^\./||; s|/[^/]*$||; p' | sort -u | head -100
  echo "\`\`\`"
  echo ""

  echo "## Python Packages (with __init__.py)"
  echo ""
  echo "\`\`\`"
  find . -name "__init__.py" ! -path '*/.*' ! -path '*/build/*' ! -path '*/dist/*' | sed 's|/__init__.py||' | sort
  echo "\`\`\`"
  echo ""

  echo "## Configuration Files"
  echo ""
  echo "\`\`\`"
  find . -maxdepth 2 \( \
    -name "package.json" \
    -o -name "pyproject.toml" \
    -o -name "setup.py" \
    -o -name "requirements.txt" \
    -o -name "Dockerfile" \
    -o -name "docker-compose.yml" \
    -o -name "pom.xml" \
    -o -name "build.gradle" \
    -o -name "build.gradle.kts" \
    -o -name "settings.gradle" \
    -o -name "settings.gradle.kts" \
    -o -name "gradle.properties" \
    -o -name "mvnw" \
    -o -name "gradlew" \
  \) -type f 2>/dev/null | sort
  echo "\`\`\`"
  echo ""

  echo "## Build & Output Directories (excluded from analysis)"
  echo ""
  echo "The index excludes these common directories:"
  echo "- \`node_modules/\` - NPM packages"
  echo "- \`dist/\`, \`build/\`, \`target/\` - Build outputs"
  echo "- \`__pycache__/\` - Python cache"
  echo "- \`.venv/\`, \`venv/\` - Virtual environments"
  echo "- \`.git/\` - Git metadata"
} > "$OUTPUT_DIR/index/markdown/architecture.md"
