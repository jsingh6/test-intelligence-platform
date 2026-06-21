"""M4: Entry point for the bug intake webhook (GitHub Actions or HTTP server)."""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from agent.gap_finder import find_gap
from agent.regression_generator import generate_regression_tc


@dataclass
class BugReport:
    issue_number: int
    title: str
    body: str
    labels: list[str]
    stack_trace: str = ""
    impacted_files: list[str] = field(default_factory=list)


def handle_bug_labeled(payload: dict, harness_root: Path, repo: str) -> None:
    """Called when a GitHub Issue gets the 'bug' label."""
    issue = payload["issue"]
    report = BugReport(
        issue_number=issue["number"],
        title=issue["title"],
        body=issue.get("body") or "",
        labels=[l["name"] for l in issue.get("labels", [])],
    )
    report.stack_trace = _extract_stack_trace(report.body)
    report.impacted_files = _files_from_stack_trace(report.stack_trace)

    gap_result = find_gap(report, harness_root)
    if gap_result.has_gap:
        generate_regression_tc(report, gap_result, harness_root, repo)


def _extract_stack_trace(body: str) -> str:
    match = re.search(r"```\s*(?:swift|text|log)?\n(.*?)```", body, re.DOTALL)
    return match.group(1) if match else ""


def _files_from_stack_trace(stack_trace: str) -> list[str]:
    # Swift stack trace lines typically contain "FileName.swift:lineNumber"
    pattern = re.compile(r"(\w+\.swift):\d+")
    return list(dict.fromkeys(pattern.findall(stack_trace)))
