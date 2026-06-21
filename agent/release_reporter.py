"""M5: Auto-generate a release readiness report on release branch cut."""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

import yaml


@dataclass
class ReleaseReport:
    release_branch: str
    generated_on: str
    total_tcs: int
    passed: int
    failed: int
    not_run: int
    p0_not_passing: list[str]
    deploy_gate: str  # "green" | "blocked"
    coverage_by_area: dict[str, dict]


def generate(harness_root: Path, release_branch: str) -> ReleaseReport:
    tcs = _load_all_test_cases(harness_root)
    total = len(tcs)
    passed = sum(1 for tc in tcs if tc.get("last_result") == "pass")
    failed = sum(1 for tc in tcs if tc.get("last_result") == "fail")
    not_run = total - passed - failed

    p0_not_passing = [
        tc["id"]
        for tc in tcs
        if tc.get("priority") == "P0" and tc.get("last_result") != "pass"
    ]
    deploy_gate = "blocked" if p0_not_passing else "green"

    coverage_by_area = _coverage_by_area(tcs)

    return ReleaseReport(
        release_branch=release_branch,
        generated_on=date.today().isoformat(),
        total_tcs=total,
        passed=passed,
        failed=failed,
        not_run=not_run,
        p0_not_passing=p0_not_passing,
        deploy_gate=deploy_gate,
        coverage_by_area=coverage_by_area,
    )


def to_markdown(report: ReleaseReport) -> str:
    gate_icon = "✅" if report.deploy_gate == "green" else "🚫"
    lines = [
        f"# Release Report — {report.release_branch}",
        f"Generated: {report.generated_on}",
        "",
        f"## Deploy Gate: {gate_icon} {report.deploy_gate.upper()}",
        "",
        "## Summary",
        f"| Status | Count |",
        f"|--------|-------|",
        f"| Passed | {report.passed} |",
        f"| Failed | {report.failed} |",
        f"| Not Run | {report.not_run} |",
        f"| **Total** | **{report.total_tcs}** |",
    ]
    if report.p0_not_passing:
        lines += ["", "## Blocking P0s", *[f"- {tc}" for tc in report.p0_not_passing]]
    lines += ["", "## Coverage by Area"]
    for area, stats in report.coverage_by_area.items():
        lines.append(f"- **{area}**: {stats['passed']}/{stats['total']} passed")
    return "\n".join(lines)


def _load_all_test_cases(harness_root: Path) -> list[dict]:
    tcs = []
    for yaml_path in (harness_root / "test-cases").glob("*.yaml"):
        if yaml_path.name.startswith("_"):
            continue
        data = yaml.safe_load(yaml_path.read_text())
        tcs.extend(data.get("test_cases", []))
    return tcs


def _coverage_by_area(tcs: list[dict]) -> dict[str, dict]:
    areas: dict[str, dict] = {}
    for tc in tcs:
        area = tc["id"].split("-")[0]
        entry = areas.setdefault(area, {"total": 0, "passed": 0})
        entry["total"] += 1
        if tc.get("last_result") == "pass":
            entry["passed"] += 1
    return areas
