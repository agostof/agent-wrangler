#!/bin/bash
# index-files.sh
# Collect all source files with file type, line count, and organization

OUTPUT_DIR="${1:-.claude}"

# File type patterns for our languages
PATTERNS=(
  "*.py"
  "*.js"
  "*.jsx"
  "*.ts"
  "*.tsx"
  "*.sh"
  "*.bash"
)

# Generate text format (simple list)
{
  echo "# Source Files Index"
  echo "Generated: $(date)"
  echo ""
  
  for pattern in "${PATTERNS[@]}"; do
    echo "## $pattern Files"
    rg --files -g "$pattern" --max-count 1000 | sort
    echo ""
  done
} > "$OUTPUT_DIR/index/text/files.txt"

# Generate JSON format (structured with metadata)
{
  echo "{"
  echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "files_by_type": {'
  
  first=true
  for pattern in "${PATTERNS[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    
    echo -n "    \"$pattern\": ["
    
    file_list=()
    while IFS= read -r file; do
      file_list+=("$file")
    done < <(rg --files -g "$pattern" --max-count 1000 | sort)
    
    first_file=true
    for file in "${file_list[@]}"; do
      if [ "$first_file" = true ]; then
        first_file=false
      else
        echo ","
      fi
      echo -n "      {\"path\": \"$file\", \"lines\": $(wc -l < "$file" 2>/dev/null || echo 0)}"
    done
    echo ""
    echo -n "    ]"
  done
  
  echo ""
  echo "  }"
  echo "}"
} > "$OUTPUT_DIR/index/json/files.json"

# Generate Markdown format (readable summary)
{
  echo "# Repository File Structure"
  echo ""
  echo "**Generated:** $(date)"
  echo ""
  echo "## File Summary by Type"
  echo ""
  
  for pattern in "${PATTERNS[@]}"; do
    count=$(rg --files -g "$pattern" --max-count 1000 | wc -l)
    lines=$(rg --files -g "$pattern" --max-count 1000 | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
    
    if [ "$count" -gt 0 ]; then
      echo "### $pattern ($count files, ~$lines lines)"
      echo ""
      echo "\`\`\`"
      rg --files -g "$pattern" --max-count 20 | sort
      if [ "$count" -gt 20 ]; then
        echo "... and $((count - 20)) more"
      fi
      echo "\`\`\`"
      echo ""
    fi
  done
  
  echo "## Directory Structure"
  echo ""
  echo "\`\`\`"
  find . -maxdepth 3 -type d \
    ! -path '*/node_modules' \
    ! -path '*/.git' \
    ! -path '*/.*' \
    ! -path '*/build/*' \
    ! -path '*/dist/*' \
    ! -path '*/__pycache__/*' \
    ! -path '*/.venv/*' \
    ! -path '*/venv/*' \
    -print | head -50
  echo "\`\`\`"
} > "$OUTPUT_DIR/index/markdown/files.md"
