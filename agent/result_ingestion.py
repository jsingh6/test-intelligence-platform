"""M5: Ingest CI test results (XCTest/JUnit XML) and update the pool."""
from __future__ import annotations

import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import yaml


@dataclass
class TestResult:
    tc_id: str
    passed: bool
    run_date: str
    duration_seconds: float


def ingest_junit_xml(xml_path: Path, harness_root: Path) -> list[TestResult]:
    results = _parse_junit(xml_path)
    _update_pool(results, harness_root)
    return results


def ingest_manual(tc_id: str, passed: bool, harness_root: Path) -> TestResult:
    result = TestResult(
        tc_id=tc_id,
        passed=passed,
        run_date=datetime.now(timezone.utc).isoformat(),
        duration_seconds=0,
    )
    _update_pool([result], harness_root)
    return result


def _parse_junit(xml_path: Path) -> list[TestResult]:
    tree = ET.parse(xml_path)
    results = []
    for testcase in tree.iter("testcase"):
        tc_id = testcase.get("name", "")
        if not tc_id.startswith(("TC", "P0", "P1", "AUTH", "TODO", "DASH", "REG")):
            # Only map if the name looks like a known TC ID
            continue
        passed = testcase.find("failure") is None and testcase.find("error") is None
        results.append(TestResult(
            tc_id=tc_id,
            passed=passed,
            run_date=datetime.now(timezone.utc).isoformat(),
            duration_seconds=float(testcase.get("time", 0)),
        ))
    return results


def _update_pool(results: list[TestResult], harness_root: Path) -> None:
    result_map = {r.tc_id: r for r in results}
    for yaml_path in (harness_root / "test-cases").glob("*.yaml"):
        if yaml_path.name.startswith("_"):
            continue
        data = yaml.safe_load(yaml_path.read_text())
        changed = False
        for tc in data.get("test_cases", []):
            if tc["id"] in result_map:
                r = result_map[tc["id"]]
                tc["last_result"] = "pass" if r.passed else "fail"
                tc["last_run_date"] = r.run_date
                changed = True
        if changed:
            yaml_path.write_text(yaml.dump(data, default_flow_style=False, sort_keys=False))
