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
    """Parse JUnit XML produced by xcodebuild -resultBundlePath.

    Test functions must follow the naming convention:
        test<Description>__<TC_ID_with_underscores>
    e.g. testLoginSuccess__AUTH_TC001  →  AUTH-TC001
         testAddFormPicker__PR1_B001_TC01  →  PR1-B001-TC01
    """
    tree = ET.parse(xml_path)
    results = []
    for testcase in tree.iter("testcase"):
        name = testcase.get("name", "")
        tc_id = _extract_tc_id(name)
        if not tc_id:
            continue
        passed = testcase.find("failure") is None and testcase.find("error") is None
        results.append(TestResult(
            tc_id=tc_id,
            passed=passed,
            run_date=datetime.now(timezone.utc).isoformat(),
            duration_seconds=float(testcase.get("time", 0)),
        ))
    return results


def _extract_tc_id(func_name: str) -> str | None:
    """Extract TC ID from a test function name using the __ separator convention."""
    if "__" not in func_name:
        return None
    suffix = func_name.rsplit("__", 1)[1]   # e.g. "PR1_B001_TC01"
    tc_id = suffix.replace("_", "-")         # e.g. "PR1-B001-TC01"
    # Sanity check — must look like a known ID pattern
    if not any(tc_id.startswith(p) for p in ("AUTH-", "PR", "REG-")):
        return None
    return tc_id


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
