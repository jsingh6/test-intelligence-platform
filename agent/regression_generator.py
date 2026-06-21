"""M4: Generate a regression test case from a bug report and log the gap."""
from __future__ import annotations

import json
import os
from datetime import date
from pathlib import Path
from typing import TYPE_CHECKING

import anthropic
import yaml

if TYPE_CHECKING:
    from agent.bug_webhook import BugReport
    from agent.gap_finder import GapResult

CLAUDE_MODEL = "claude-sonnet-4-6"


def generate_regression_tc(
    report: "BugReport",
    gap: "GapResult",
    harness_root: Path,
    repo: str,
) -> None:
    tc = _call_claude(report, gap)
    _append_to_pool(tc, harness_root, report.issue_number)
    _append_to_audit_log(report, gap, tc, harness_root, repo)


def _call_claude(report: "BugReport", gap: "GapResult") -> dict:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    prompt = f"""\
Bug #{report.issue_number}: {report.title}

Description:
{report.body[:2000]}

Stack trace:
{report.stack_trace}

Impacted files: {', '.join(report.impacted_files)}
Matched behaviors: {', '.join(gap.matched_behaviors) or 'none'}
Gap explanation: {gap.gap_explanation}

Write a regression test case that would catch this bug. Return a JSON object with:
  title, priority (P0 or P1), preconditions (list), steps (list), expected_result
"""
    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}],
    )
    return json.loads(response.content[0].text)


def _append_to_pool(tc: dict, harness_root: Path, issue_number: int) -> None:
    area = "regression"
    tc_file = harness_root / "test-cases" / f"{area}_tc.yaml"
    existing: dict = {"schema_version": "1.0", "test_cases": []}
    if tc_file.exists():
        existing = yaml.safe_load(tc_file.read_text())
    count = len(existing["test_cases"]) + 1
    tc_id = f"REG-TC{str(count).zfill(3)}"
    existing["test_cases"].append({
        "id": tc_id,
        "behavior_id": None,
        "regression_for_bug": f"#{issue_number}",
        "automation_status": "automation-candidate",
        **tc,
    })
    tc_file.write_text(yaml.dump(existing, default_flow_style=False, sort_keys=False))


def _append_to_audit_log(
    report: "BugReport",
    gap: "GapResult",
    tc: dict,
    harness_root: Path,
    repo: str,
) -> None:
    log_file = harness_root / "audit" / "gap_log.yaml"
    entries: list = []
    if log_file.exists():
        entries = yaml.safe_load(log_file.read_text()) or []
    entries.append({
        "date": date.today().isoformat(),
        "bug_issue": f"#{report.issue_number}",
        "title": report.title,
        "impacted_files": report.impacted_files,
        "matched_behaviors": gap.matched_behaviors,
        "existing_tcs": gap.existing_tc_ids,
        "gap_explanation": gap.gap_explanation,
        "regression_tc_title": tc.get("title"),
    })
    log_file.write_text(yaml.dump(entries, default_flow_style=False))
