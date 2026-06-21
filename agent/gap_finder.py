"""M4: Determine whether the bug scenario is covered by the test pool."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

import yaml

if TYPE_CHECKING:
    from agent.bug_webhook import BugReport


@dataclass
class GapResult:
    has_gap: bool
    matched_behaviors: list[str]
    existing_tc_ids: list[str]
    gap_explanation: str


def find_gap(report: "BugReport", harness_root: Path) -> GapResult:
    matched_behaviors = _behaviors_for_files(report.impacted_files, harness_root)
    existing_tcs = _test_cases_for_behaviors(matched_behaviors, harness_root)

    if not matched_behaviors:
        return GapResult(
            has_gap=True,
            matched_behaviors=[],
            existing_tc_ids=[],
            gap_explanation="No behavior registry entries found for the impacted files.",
        )

    if not existing_tcs:
        return GapResult(
            has_gap=True,
            matched_behaviors=matched_behaviors,
            existing_tc_ids=[],
            gap_explanation=(
                f"Behaviors found ({', '.join(matched_behaviors)}) but no test cases cover them."
            ),
        )

    return GapResult(
        has_gap=False,
        matched_behaviors=matched_behaviors,
        existing_tc_ids=existing_tcs,
        gap_explanation="",
    )


def _behaviors_for_files(impacted_files: list[str], harness_root: Path) -> list[str]:
    ids = []
    for yaml_path in (harness_root / "behaviors").glob("*.yaml"):
        if yaml_path.name.startswith("_"):
            continue
        data = yaml.safe_load(yaml_path.read_text())
        for b in data.get("behaviors", []):
            for file in impacted_files:
                if any(file in fp for fp in b.get("file_paths", [])):
                    ids.append(b["id"])
    return list(dict.fromkeys(ids))


def _test_cases_for_behaviors(behavior_ids: list[str], harness_root: Path) -> list[str]:
    tc_ids = []
    for yaml_path in (harness_root / "test-cases").glob("*.yaml"):
        if yaml_path.name.startswith("_"):
            continue
        data = yaml.safe_load(yaml_path.read_text())
        for tc in data.get("test_cases", []):
            if tc.get("behavior_id") in behavior_ids:
                tc_ids.append(tc["id"])
    return tc_ids
