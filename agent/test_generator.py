"""M3: Generate P0–P3 test cases from an approved behavior summary."""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from typing import Literal

import anthropic

from agent.behavior_summary import BehaviorSummary

CLAUDE_MODEL = "claude-sonnet-4-6"
Priority = Literal["P0", "P1", "P2", "P3"]


@dataclass
class GeneratedTestCase:
    tc_id: str
    behavior_id: str
    priority: Priority
    title: str
    preconditions: list[str]
    steps: list[str]
    expected_result: str
    test_type: str  # happy_path | negative | boundary | error_state | async_timing


def generate_for_behavior(behavior_id: str, behavior_summary: str) -> list[GeneratedTestCase]:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    prompt = f"""\
Behavior ID: {behavior_id}
Behavior: {behavior_summary}

Generate test cases covering all applicable patterns:
1. happy_path — the expected successful flow
2. negative — wrong input, unauthorized state, missing data
3. boundary — edge values, empty collections, max lengths
4. error_state — network failure, timeout, server error
5. async_timing — race conditions, loading states, debounce

For each test case return a JSON object with:
  title, priority (P0/P1/P2/P3), test_type, preconditions (list), steps (list), expected_result

Return a JSON array of test case objects. Only include patterns that genuinely apply.
P0 = must-pass before any release. P1 = should-pass. P2 = nice to have. P3 = low-risk edge case.
"""

    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = json.loads(response.content[0].text)
    results = []
    for i, tc in enumerate(raw, start=1):
        suffix = str(i).zfill(3)
        results.append(GeneratedTestCase(
            tc_id=f"{behavior_id}-TC{suffix}",
            behavior_id=behavior_id,
            **tc,
        ))
    return results
