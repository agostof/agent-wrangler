#!/bin/bash
# index-annotations.sh
# Extract TODO, FIXME, HACK, and other code annotations

OUTPUT_DIR="${1:-.claude}"

# Generate text format (quick scan)
{
  echo "# Code Annotations & Markers"
  echo "Generated: $(date)"
  echo ""
  
  echo "## TODO Items"
  rg "TODO|FIXME|XXX|HACK" --line-number --no-heading | head -50
  echo ""
  
  echo "## BUG Reports"
  rg "BUG|ISSUE|BROKEN|DEPRECATED" --line-number --no-heading | head -30
  echo ""
  
  echo "## WARN/NOTE Items"
  rg "WARN|NOTE|IMPORTANT|CAUTION" --line-number --no-heading | head -30
  
} > "$OUTPUT_DIR/index/text/annotations.txt"

# Generate JSON format
{
  echo "{"
  echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "annotations": {'
  
  echo '    "todo": ['
  rg "TODO" --line-number --no-heading -C 0 | awk -F: '{print "      {\"file\": \"" $1 "\", \"line\": " $2 ", \"text\": \"" $3 "\"}"}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'
  
  echo '    "fixme": ['
  rg "FIXME" --line-number --no-heading -C 0 | awk -F: '{print "      {\"file\": \"" $1 "\", \"line\": " $2 ", \"text\": \"" $3 "\"}"}' | head -50 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'
  
  echo '    "hack": ['
  rg "HACK|KLUDGE" --line-number --no-heading -C 0 | awk -F: '{print "      {\"file\": \"" $1 "\", \"line\": " $2 ", \"text\": \"" $3 "\"}"}' | head -30 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ],'
  
  echo '    "bug_markers": ['
  rg "BUG|BROKEN|ISSUE" --line-number --no-heading -C 0 | awk -F: '{print "      {\"file\": \"" $1 "\", \"line\": " $2 ", \"text\": \"" $3 "\"}"}' | head -30 | paste -sd ',' - | sed 's/,$//'
  echo ""
  echo '    ]'
  
  echo '  }'
  echo "}"
} > "$OUTPUT_DIR/index/json/annotations.json"

# Generate Markdown format
{
  echo "# Code Annotations & Work Items"
  echo ""
  echo "**Generated:** $(date)"
  echo ""
  echo "Quick reference to TODOs, FIXMEs, and other code markers."
  echo ""
  
  echo "## TODO Items"
  echo ""
  count=$(rg "TODO" --line-number --no-heading | wc -l)
  echo "**Count: $count**"
  echo ""
  echo "\`\`\`"
  rg "TODO" --line-number | head -30
  if [ "$count" -gt 30 ]; then
    echo "... and $((count - 30)) more"
  fi
  echo "\`\`\`"
  echo ""
  
  echo "## FIXME Items"
  echo ""
  count=$(rg "FIXME" --line-number --no-heading | wc -l)
  echo "**Count: $count**"
  echo ""
  echo "\`\`\`"
  rg "FIXME" --line-number | head -30
  if [ "$count" -gt 30 ]; then
    echo "... and $((count - 30)) more"
  fi
  echo "\`\`\`"
  echo ""
  
  echo "## HACK / KLUDGE Items"
  echo ""
  count=$(rg "HACK|KLUDGE" --line-number --no-heading | wc -l)
  echo "**Count: $count**"
  echo ""
  if [ "$count" -gt 0 ]; then
    echo "\`\`\`"
    rg "HACK|KLUDGE" --line-number | head -20
    if [ "$count" -gt 20 ]; then
      echo "... and $((count - 20)) more"
    fi
    echo "\`\`\`"
  fi
  echo ""
  
  echo "## Bug Markers (BUG/BROKEN/ISSUE)"
  echo ""
  count=$(rg "BUG|BROKEN|ISSUE" --line-number --no-heading | wc -l)
  echo "**Count: $count**"
  echo ""
  if [ "$count" -gt 0 ]; then
    echo "\`\`\`"
    rg "BUG|BROKEN|ISSUE" --line-number | head -25
    if [ "$count" -gt 25 ]; then
      echo "... and $((count - 25)) more"
    fi
    echo "\`\`\`"
  fi
  
} > "$OUTPUT_DIR/index/markdown/annotations.md"
