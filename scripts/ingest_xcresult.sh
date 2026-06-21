#!/usr/bin/env bash
# Ingest test results from an Xcode result bundle and update the TC pool.
# Usage: ./scripts/ingest_xcresult.sh path/to/Test.xcresult
#
# Requires: xcodebuild (Xcode), python3, pyyaml
# The JUnit XML is exported to a temp file, parsed by result_ingestion.py,
# and last_result / last_run_date are written back into harness/test-cases/*.yaml.
# Run `git commit harness/test-cases/` after this to persist results.
set -euo pipefail

XCRESULT="${1:?Usage: $0 path/to/Test.xcresult}"
JUNIT_TMP=$(mktemp /tmp/tip-junit-XXXX.xml)

echo "Exporting JUnit XML from $XCRESULT…"
xcrun xcresulttool get --format json --path "$XCRESULT" \
  | python3 - <<'PYEOF'
import json, sys, xml.etree.ElementTree as ET
from pathlib import Path

data = json.load(sys.stdin)
root = ET.Element("testsuites")

def walk(node, suite_el):
    for action in node.get("subtests", {}).get("_values", []):
        name = action.get("identifier", {}).get("_value", "")
        duration = action.get("duration", {}).get("_value", "0")
        status = action.get("testStatus", {}).get("_value", "")
        tc = ET.SubElement(suite_el, "testcase", name=name, time=str(duration))
        if status != "Success":
            ET.SubElement(tc, "failure", message=status)
    for sub in node.get("subtests", {}).get("_values", []):
        walk(sub, suite_el)

for action in data.get("actions", {}).get("_values", []):
    tests = action.get("actionResult", {}).get("testsRef", {})
    suite = ET.SubElement(root, "testsuite", name="TIPUITests")
    walk(tests, suite)

ET.ElementTree(root).write(sys.stdout.buffer)
PYEOF > "$JUNIT_TMP"

echo "Ingesting results…"
python3 - "$JUNIT_TMP" <<'PYEOF'
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))
from agent.result_ingestion import ingest_junit_xml
results = ingest_junit_xml(Path(sys.argv[1]), Path("harness"))
for r in results:
    status = "PASS" if r.passed else "FAIL"
    print(f"  {r.tc_id} → {status}")
print(f"Updated {len(results)} test case(s) in harness/test-cases/")
PYEOF

rm -f "$JUNIT_TMP"
echo "Done. Run 'git commit harness/test-cases/' to persist results."
