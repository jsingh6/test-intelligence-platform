"""M3: Commit approved test cases to the pool and tag @test-ids in source files."""
from __future__ import annotations

import subprocess
from pathlib import Path

import yaml

from agent.test_generator import GeneratedTestCase


def commit_to_pool(
    test_cases: list[GeneratedTestCase],
    harness_root: Path,
    pr_number: int,
    area: str,
) -> None:
    tc_file = harness_root / "test-cases" / f"{area}_tc.yaml"
    existing: dict = {"schema_version": "1.0", "test_cases": []}
    if tc_file.exists():
        existing = yaml.safe_load(tc_file.read_text())

    ids_in_file = {tc["id"] for tc in existing.get("test_cases", [])}
    new_entries = []
    for tc in test_cases:
        if tc.tc_id not in ids_in_file:
            new_entries.append({
                "id": tc.tc_id,
                "behavior_id": tc.behavior_id,
                "priority": tc.priority,
                "title": tc.title,
                "preconditions": tc.preconditions,
                "steps": tc.steps,
                "expected_result": tc.expected_result,
                "automation_status": "automation-candidate" if tc.priority in ("P0", "P1") else "manual",
                "automation_tc_id": None,
                "last_result": None,
                "last_run_date": None,
                "pr_of_origin": f"#{pr_number}",
                "regression_for_bug": None,
            })

    if not new_entries:
        return

    existing["test_cases"].extend(new_entries)
    tc_file.write_text(yaml.dump(existing, default_flow_style=False, sort_keys=False))

    subprocess.run(
        ["git", "add", str(tc_file)],
        check=True,
    )
    subprocess.run(
        ["git", "commit", "-m", f"harness: add {len(new_entries)} test cases from PR #{pr_number}"],
        check=True,
        env={"GIT_AUTHOR_NAME": "tip-bot", "GIT_AUTHOR_EMAIL": "tip-bot@users.noreply.github.com"},
    )
