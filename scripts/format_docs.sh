#!/usr/bin/env bash
# Formats all Markdown specification documents using mdformat (CommonMark + GFM)
set -euo pipefail

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=true
fi

# Collect all repository markdown files excluding submodules and git
FILES=$(find . -name "*.md" -not -path "*/code/*" -not -path "*/.git/*" | sort)

if [ "$CHECK_ONLY" = true ]; then
    echo "Checking Markdown formatting with mdformat..."
    mdformat --check --wrap keep $FILES
    echo "All Markdown specification documents are cleanly formatted."
else
    echo "Formatting Markdown specification documents with mdformat..."
    mdformat --wrap keep $FILES
    echo "Formatting complete."
fi
