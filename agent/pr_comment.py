"""M2: Post the behavior summary as a structured PR comment and manage the soft-block label."""
from __future__ import annotations

import os

import httpx

from agent.behavior_summary import BehaviorSummary

NEEDS_REVIEW_LABEL = "needs-behavior-review"
APPROVED_LABEL = "behavior-approved"


def post_summary(pr_number: int, repo: str, summary: BehaviorSummary) -> None:
    body = _render_comment(summary)
    _post_comment(pr_number, repo, body)
    _apply_label(pr_number, repo, NEEDS_REVIEW_LABEL)


def handle_approval(pr_number: int, repo: str, comment_body: str) -> bool:
    """Return True if the comment is a valid approval signal."""
    if "/approve-behaviors" not in comment_body.lower():
        return False
    _remove_label(pr_number, repo, NEEDS_REVIEW_LABEL)
    _apply_label(pr_number, repo, APPROVED_LABEL)
    return True


def _render_comment(s: BehaviorSummary) -> str:
    lines = ["## Behavior Review\n", s.raw_summary, ""]

    def section(title: str, items: list[str], emoji: str) -> None:
        if items:
            lines.append(f"### {emoji} {title}")
            lines.extend(f"- {item}" for item in items)
            lines.append("")

    section("New Behaviors", s.new_behaviors, "🆕")
    section("Modified Behaviors", s.modified_behaviors, "✏️")
    section("Deleted Behaviors", s.deleted_behaviors, "🗑️")
    section("Unchanged Behaviors", s.unchanged_behaviors, "✅")

    if s.clarifying_question:
        lines.append(f"> **Question for author:** {s.clarifying_question}")
        lines.append("")

    lines += [
        "---",
        "_To approve this summary, reply with `/approve-behaviors`._",
        "_To request changes, reply with your edits and I'll regenerate._",
    ]
    return "\n".join(lines)


def _client() -> httpx.Client:
    return httpx.Client(
        headers={
            "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
            "Accept": "application/vnd.github+json",
        }
    )


def _post_comment(pr_number: int, repo: str, body: str) -> None:
    with _client() as c:
        c.post(
            f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments",
            json={"body": body},
        ).raise_for_status()


def _apply_label(pr_number: int, repo: str, label: str) -> None:
    with _client() as c:
        c.post(
            f"https://api.github.com/repos/{repo}/issues/{pr_number}/labels",
            json={"labels": [label]},
        ).raise_for_status()


def _remove_label(pr_number: int, repo: str, label: str) -> None:
    with _client() as c:
        c.delete(
            f"https://api.github.com/repos/{repo}/issues/{pr_number}/labels/{label}",
        )
