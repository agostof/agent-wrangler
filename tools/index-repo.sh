#!/bin/bash
# index-repo.sh
# Main orchestrator for repository indexing
# Usage: ./index-repo.sh [output_dir]

set -e

OUTPUT_DIR="${1:-.claude}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create output directory structure
mkdir -p "$OUTPUT_DIR/index"
mkdir -p "$OUTPUT_DIR/index/text"
mkdir -p "$OUTPUT_DIR/index/json"
mkdir -p "$OUTPUT_DIR/index/markdown"

echo "🔍 Indexing repository..."
echo "📁 Output directory: $OUTPUT_DIR/index"
echo ""

# Run individual indexing scripts
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "1️⃣  Collecting source files..."
"$script_dir/index-files.sh" "$OUTPUT_DIR"

echo "2️⃣  Extracting definitions..."
"$script_dir/index-definitions.sh" "$OUTPUT_DIR"

echo "3️⃣  Finding exports & imports..."
"$script_dir/index-imports.sh" "$OUTPUT_DIR"

echo "4️⃣  Mapping architecture..."
"$script_dir/index-architecture.sh" "$OUTPUT_DIR"

echo "5️⃣  Indexing annotations..."
"$script_dir/index-annotations.sh" "$OUTPUT_DIR"

echo "6️⃣  Generating summaries..."
"$script_dir/index-summary.sh" "$OUTPUT_DIR"

echo ""
echo "✅ Indexing complete!"
echo ""
echo "📄 Output files:"
ls -lh "$OUTPUT_DIR/index"/{text,json,markdown}/ 2>/dev/null | grep -v "^total" || echo "  (no files generated yet)"
echo ""
echo "💡 Next step: run 'claude' to start Claude Code in this directory"
