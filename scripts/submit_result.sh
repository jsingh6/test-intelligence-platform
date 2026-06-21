#!/usr/bin/env bash
# M5: Submit a manual pass/fail result for a test case.
# Usage: ./scripts/submit_result.sh <TC_ID> <pass|fail>
set -euo pipefail

TC_ID="${1:?Usage: $0 <TC_ID> <pass|fail>}"
RESULT="${2:?Usage: $0 <TC_ID> <pass|fail>}"

if [[ "$RESULT" != "pass" && "$RESULT" != "fail" ]]; then
  echo "Error: result must be 'pass' or 'fail'" >&2
  exit 1
fi

python3 -c "
from pathlib import Path
from agent.result_ingestion import ingest_manual

result = ingest_manual('$TC_ID', $( [[ '$RESULT' == 'pass' ]] && echo 'True' || echo 'False'), Path('harness'))
print(f'Recorded: {result.tc_id} → {\"PASS\" if result.passed else \"FAIL\"} at {result.run_date}')
"
