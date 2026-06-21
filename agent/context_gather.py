"""M2: Collect everything a PR agent needs before calling Claude."""
from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import httpx


@dataclass
class PRContext:
    pr_number: int
    title: str
    description: str
    diff: str
    changed_files: list[str]
    comments: list[str]
    existing_behaviors: dict[str, str]  # file_path -> behavior YAML content
    linked_ticket_body: Optional[str] = None
    image_urls: list[str] = field(default_factory=list)


def gather(pr_number: int, repo: str, harness_root: Path) -> PRContext:
    """
    Pull all context for a PR from GitHub and the local behavior registry.
    Called by the GitHub Action on pr_open / synchronize events.
    """
    token = os.environ["GITHUB_TOKEN"]
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    base = f"https://api.github.com/repos/{repo}"

    with httpx.Client(headers=headers) as client:
        pr = client.get(f"{base}/pulls/{pr_number}").raise_for_status().json()
        diff_text = client.get(
            f"{base}/pulls/{pr_number}",
            headers={**headers, "Accept": "application/vnd.github.v3.diff"},
        ).raise_for_status().text
        files = client.get(f"{base}/pulls/{pr_number}/files").raise_for_status().json()
        comments_raw = client.get(f"{base}/issues/{pr_number}/comments").raise_for_status().json()

    changed_files = [f["filename"] for f in files]
    comments = [c["body"] for c in comments_raw]

    existing_behaviors = _load_behaviors_for_files(changed_files, harness_root)

    return PRContext(
        pr_number=pr_number,
        title=pr["title"],
        description=pr.get("body") or "",
        diff=diff_text,
        changed_files=changed_files,
        comments=comments,
        existing_behaviors=existing_behaviors,
    )


def _load_behaviors_for_files(changed_files: list[str], harness_root: Path) -> dict[str, str]:
    behaviors: dict[str, str] = {}
    behaviors_dir = harness_root / "behaviors"
    if not behaviors_dir.exists():
        return behaviors
    for yaml_path in behaviors_dir.glob("*.yaml"):
        if yaml_path.name.startswith("_"):
            continue
        content = yaml_path.read_text()
        for file in changed_files:
            if file in content:
                behaviors[str(yaml_path)] = content
                break
    return behaviors
