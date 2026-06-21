"""
M3: Triggered after /approve-behaviors.
Reads new behaviors from the bot's summary comment, generates test cases
via Claude, posts a per-case review checklist, and commits approved cases
to harness/test-cases/.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

import anthropic
import httpx
import yaml

CLAUDE_MODEL = "claude-sonnet-4-6"
TEST_PATTERNS = ["happy_path", "negative", "boundary", "error_state"]


@dataclass
class GeneratedCase:
    tc_id: str
    behavior_id: str
    behavior_summary: str
    priority: str
    title: str
    test_type: str
    preconditions: list[str]
    steps: list[str]
    expected_result: str


def run(pr_number: int, repo: str, harness_root: Path) -> None:
    behaviors = _fetch_new_behaviors(pr_number, repo)
    if not behaviors:
        print("No new behaviors found in summary comment — nothing to generate.")
        return

    print(f"Generating test cases for {len(behaviors)} new behaviors...")
    all_cases: list[GeneratedCase] = []
    for i, text in enumerate(behaviors, start=1):
        behavior_id = _behavior_id(pr_number, i)
        cases = _generate_cases(behavior_id, text)
        all_cases.extend(cases)
        print(f"  {behavior_id}: {len(cases)} cases")

    _commit_to_pool(all_cases, harness_root, pr_number)
    _post_checklist(pr_number, repo, all_cases)
    print("M3 complete.")


# ── Behavior extraction ────────────────────────────────────────────────────────

def _fetch_new_behaviors(pr_number: int, repo: str) -> list[str]:
    token = os.environ["GITHUB_TOKEN"]
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    with httpx.Client(headers=headers) as c:
        comments = c.get(
            f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments"
        ).raise_for_status().json()

    for comment in reversed(comments):
        body = comment.get("body", "")
        if "## Behavior Review" in body:
            return _parse_new_behaviors(body)
    return []


def _parse_new_behaviors(comment_body: str) -> list[str]:
    match = re.search(
        r"###\s*🆕 New Behaviors\s*\n(.*?)(?=\n###|\Z)", comment_body, re.DOTALL
    )
    if not match:
        return []
    section = match.group(1)
    return [
        line.lstrip("- ").strip()
        for line in section.splitlines()
        if line.strip().startswith("-")
    ]


def _behavior_id(pr_number: int, index: int) -> str:
    return f"PR{pr_number}-B{str(index).zfill(3)}"


# ── Test case generation ───────────────────────────────────────────────────────

def _generate_cases(behavior_id: str, behavior_text: str) -> list[GeneratedCase]:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    prompt = f"""\
Behavior ID: {behavior_id}
Behavior: {behavior_text}

Generate test cases covering the applicable patterns from this list:
- happy_path: the expected successful flow
- negative: wrong input, invalid state, or edge-case rejection
- boundary: empty values, maximum lengths, defaults
- error_state: system/API failure, unexpected state

For each applicable pattern return a JSON object with:
  "title", "priority" (P0/P1/P2/P3), "test_type", "preconditions" (list), "steps" (list), "expected_result"

Return a JSON array. Only include patterns that genuinely apply to this behavior.
P0 = must pass before any release. P1 = high value. P2 = nice to have. P3 = low-risk edge case.
Respond with ONLY the JSON array, no markdown fences.
"""

    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )

    text = response.content[0].text.strip()
    # Strip fences if present
    match = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.DOTALL)
    text = match.group(1) if match else text

    raw_cases = json.loads(text)
    results = []
    for i, tc in enumerate(raw_cases, start=1):
        results.append(GeneratedCase(
            tc_id=f"{behavior_id}-TC{str(i).zfill(2)}",
            behavior_id=behavior_id,
            behavior_summary=behavior_text,
            priority=tc["priority"],
            title=tc["title"],
            test_type=tc["test_type"],
            preconditions=tc.get("preconditions", []),
            steps=tc["steps"],
            expected_result=tc["expected_result"],
        ))
    return results


# ── Pool commit ────────────────────────────────────────────────────────────────

def _commit_to_pool(cases: list[GeneratedCase], harness_root: Path, pr_number: int) -> None:
    tc_file = harness_root / "test-cases" / "todos_priority_tc.yaml"
    existing: dict = {"schema_version": "1.0", "test_cases": []}
    if tc_file.exists():
        existing = yaml.safe_load(tc_file.read_text()) or existing

    existing_ids = {tc["id"] for tc in existing.get("test_cases", [])}
    new_entries = []
    for c in cases:
        if c.tc_id not in existing_ids:
            new_entries.append({
                "id": c.tc_id,
                "behavior_id": c.behavior_id,
                "priority": c.priority,
                "title": c.title,
                "test_type": c.test_type,
                "preconditions": c.preconditions,
                "steps": c.steps,
                "expected_result": c.expected_result,
                "automation_status": "automation-candidate" if c.priority in ("P0", "P1") else "manual",
                "automation_tc_id": None,
                "last_result": None,
                "last_run_date": None,
                "pr_of_origin": f"#{pr_number}",
                "regression_for_bug": None,
            })

    if not new_entries:
        print("All cases already in pool.")
        return

    existing["test_cases"].extend(new_entries)
    tc_file.write_text(yaml.dump(existing, default_flow_style=False, sort_keys=False, allow_unicode=True))

    env = {
        **os.environ,
        "GIT_AUTHOR_NAME": "tip-bot",
        "GIT_AUTHOR_EMAIL": "tip-bot@users.noreply.github.com",
        "GIT_COMMITTER_NAME": "tip-bot",
        "GIT_COMMITTER_EMAIL": "tip-bot@users.noreply.github.com",
    }
    subprocess.run(["git", "add", str(tc_file)], check=True, env=env)
    subprocess.run(
        ["git", "commit", "-m",
         f"harness: add {len(new_entries)} test cases from PR #{pr_number} (M3)"],
        check=True, env=env,
    )
    subprocess.run(["git", "push"], check=True, env=env)
    print(f"Committed {len(new_entries)} test cases to {tc_file.name}")


# ── PR checklist comment ───────────────────────────────────────────────────────

def _post_checklist(pr_number: int, repo: str, cases: list[GeneratedCase]) -> None:
    p0_p1 = [c for c in cases if c.priority in ("P0", "P1")]
    p2_p3 = [c for c in cases if c.priority in ("P2", "P3")]

    lines = [
        "## Test Case Pool — Review Checklist",
        "",
        f"Generated **{len(cases)} test cases** for {len({c.behavior_id for c in cases})} new behaviors. "
        f"**{len(p0_p1)} P0/P1** cases will become automation candidates.",
        "",
    ]

    def tc_block(c: GeneratedCase) -> str:
        steps = "\n".join(f"  {i+1}. {s}" for i, s in enumerate(c.steps))
        pre = "\n".join(f"  - {p}" for p in c.preconditions) if c.preconditions else "  - None"
        return (
            f"<details>\n"
            f"<summary><b>{c.tc_id}</b> [{c.priority}] {c.title} <code>{c.test_type}</code></summary>\n\n"
            f"**Behavior:** {c.behavior_summary}\n\n"
            f"**Preconditions:**\n{pre}\n\n"
            f"**Steps:**\n{steps}\n\n"
            f"**Expected:** {c.expected_result}\n\n"
            f"</details>"
        )

    if p0_p1:
        lines.append("### 🔴 P0 / P1 — Automation Candidates")
        lines.extend(tc_block(c) for c in p0_p1)
        lines.append("")

    if p2_p3:
        lines.append("### 🟡 P2 / P3")
        lines.extend(tc_block(c) for c in p2_p3)
        lines.append("")

    lines += [
        "---",
        f"All {len(cases)} cases committed to `harness/test-cases/todos_priority_tc.yaml`. "
        "P0/P1 cases will be filed as automation-candidate GitHub Issues.",
    ]

    body = "\n".join(lines)
    token = os.environ["GITHUB_TOKEN"]
    with httpx.Client(headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}) as c:
        c.post(
            f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments",
            json={"body": body},
        ).raise_for_status()
