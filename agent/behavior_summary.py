"""M2: Call Claude to generate a behavior summary or delta for a PR."""
from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Optional

import anthropic

from agent.context_gather import PRContext

CLAUDE_MODEL = "claude-sonnet-4-6"


@dataclass
class BehaviorSummary:
    new_behaviors: list[str]
    modified_behaviors: list[str]
    deleted_behaviors: list[str]
    unchanged_behaviors: list[str]
    clarifying_question: Optional[str]
    raw_summary: str


SYSTEM_PROMPT = """\
You are a senior quality engineer reviewing a pull request. \
Your job is to describe behavioral changes in plain English — not code changes. \
A "behavior" is something the system does that a user or another system can observe. \
When an existing behavior registry is provided, output only a delta. \
If the PR description is sparse, ask ONE clarifying question.\
"""


def generate(ctx: PRContext) -> BehaviorSummary:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    registry_section = ""
    if ctx.existing_behaviors:
        sections = "\n\n".join(
            f"### {path}\n{content}" for path, content in ctx.existing_behaviors.items()
        )
        registry_section = f"\n\n## Existing Behavior Registry\n{sections}"

    user_message = f"""\
## PR #{ctx.pr_number}: {ctx.title}

### Description
{ctx.description or "(no description provided)"}

### Changed Files
{chr(10).join(f"- {f}" for f in ctx.changed_files)}

### Diff
```diff
{ctx.diff[:8000]}
```
{registry_section}

Return a JSON object with keys:
  new_behaviors, modified_behaviors, deleted_behaviors, unchanged_behaviors (each a list of plain-English strings),
  clarifying_question (string or null),
  raw_summary (a single paragraph for the PR comment)
"""

    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=1024,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": user_message}],
    )

    import json
    data = json.loads(response.content[0].text)
    return BehaviorSummary(**data)
