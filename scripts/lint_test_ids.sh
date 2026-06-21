#!/usr/bin/env bash
# M1: Flag public functions in changed Swift files that are missing @test-ids annotations.
# Usage: ./scripts/lint_test_ids.sh [diff base ref, default: main]
set -euo pipefail

BASE_REF="${1:-main}"
FAILED=0

changed_swift_files=$(git diff --name-only "$BASE_REF"...HEAD -- '*.swift' 2>/dev/null || \
                      git diff --name-only HEAD -- '*.swift')

if [[ -z "$changed_swift_files" ]]; then
  echo "No Swift files changed. Nothing to lint."
  exit 0
fi

while IFS= read -r file; do
  [[ -f "$file" ]] || continue

  # Find public/internal func/class/struct lines
  while IFS= read -r line_num; do
    # Check if the preceding line (or the line itself) has a @test-ids comment
    context=$(sed -n "$((line_num - 3)),$((line_num))p" "$file")
    if ! echo "$context" | grep -q "@test-ids"; then
      echo "WARN: $file:$line_num — public declaration missing @test-ids annotation"
      FAILED=1
    fi
  done < <(grep -n "^\s*\(public\|internal\)\s*\(func\|class\|struct\|enum\)" "$file" | cut -d: -f1)

done <<< "$changed_swift_files"

if [[ $FAILED -eq 1 ]]; then
  echo ""
  echo "One or more declarations are missing @test-ids annotations."
  echo "Add a comment above the declaration: // @test-ids: TC001, TC002"
  exit 1
fi

echo "All changed Swift declarations have @test-ids annotations."
