"""M5: Match existing automation (without @tc-id) to pool entries via Claude."""
from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path

import anthropic

CLAUDE_MODEL = "claude-sonnet-4-6"


@dataclass
class MappingCandidate:
    test_function: str
    matched_tc_id: str
    confidence: float  # 0.0 – 1.0
    reasoning: str


def map_unannotated_tests(
    test_file: Path,
    pool_summaries: list[dict],
    threshold: float = 0.7,
) -> list[MappingCandidate]:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    source = test_file.read_text()

    pool_json = json.dumps(
        [{"id": tc["id"], "title": tc["title"]} for tc in pool_summaries],
        indent=2,
    )

    prompt = f"""\
Below is a Swift test file that lacks @tc-id annotations.
Match each test function to the closest test case in the pool.

## Test file
```swift
{source[:6000]}
```

## Pool entries
{pool_json}

Return a JSON array. Each element:
  {{ "test_function": "...", "matched_tc_id": "...", "confidence": 0.0-1.0, "reasoning": "..." }}

Only include matches with confidence >= {threshold}.
"""

    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = json.loads(response.content[0].text)
    return [MappingCandidate(**item) for item in raw]
