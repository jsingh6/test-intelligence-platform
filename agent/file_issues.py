"""
M3 final step: file GitHub Issues for P0/P1 test cases and write
the issue URL back into the pool YAML.
"""
from __future__ import annotations

import os
import time
from pathlib import Path

import httpx
import yaml

LABEL = "automation-candidate"
AUTOMATION_LABEL_COLOR = "0075ca"


def run(harness_root: Path, repo: str) -> None:
    _ensure_label(repo)
    for yaml_path in sorted((harness_root / "test-cases").glob("*.yaml")):
        if yaml_path.name.startswith("_"):
            continue
        data = yaml.safe_load(yaml_path.read_text())
        changed = False
        for tc in data.get("test_cases", []):
            if tc.get("priority") not in ("P0", "P1"):
                continue
            if tc.get("issue_url"):
                print(f"  skip {tc['id']} — already has issue")
                continue
            url = _create_issue(tc, repo)
            tc["issue_url"] = url
            tc["automation_status"] = "automation-candidate"
            changed = True
            print(f"  filed {tc['id']} [{tc['priority']}] → {url}")
            time.sleep(0.5)   # stay well within GitHub rate limits
        if changed:
            yaml_path.write_text(
                yaml.dump(data, default_flow_style=False, sort_keys=False, allow_unicode=True)
            )
            print(f"Updated {yaml_path.name}")


def _create_issue(tc: dict, repo: str) -> str:
    steps_md = "\n".join(f"{i+1}. {s}" for i, s in enumerate(tc.get("steps", [])))
    pre_md   = "\n".join(f"- {p}" for p in tc.get("preconditions", [])) or "None"
    body = f"""\
## Test Case `{tc['id']}` — {tc['title']}

| Field | Value |
|-------|-------|
| **Priority** | {tc['priority']} |
| **Behavior** | `{tc['behavior_id']}` |
| **Type** | {tc.get('test_type', 'N/A')} |
| **PR of origin** | {tc.get('pr_of_origin', 'N/A')} |

### Preconditions
{pre_md}

### Steps
{steps_md}

### Expected Result
{tc.get('expected_result', '')}

---
*Filed automatically by TIP M3 pipeline. Pool entry: `harness/test-cases/`. TC ID: `{tc['id']}`.*
"""
    token = os.environ["GITHUB_TOKEN"]
    with httpx.Client(
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    ) as client:
        resp = client.post(
            f"https://api.github.com/repos/{repo}/issues",
            json={
                "title": f"[{tc['id']}] {tc['title']}",
                "body": body,
                "labels": [LABEL],
            },
        ).raise_for_status().json()
    return resp["html_url"]


def _ensure_label(repo: str) -> None:
    token = os.environ["GITHUB_TOKEN"]
    with httpx.Client(
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    ) as client:
        resp = client.get(f"https://api.github.com/repos/{repo}/labels/{LABEL}")
        if resp.status_code == 404:
            client.post(
                f"https://api.github.com/repos/{repo}/labels",
                json={"name": LABEL, "color": AUTOMATION_LABEL_COLOR,
                      "description": "Test case needs automation coverage"},
            ).raise_for_status()
            print(f"Created label '{LABEL}'")


if __name__ == "__main__":
    import sys
    repo = sys.argv[1] if len(sys.argv) > 1 else "jsingh6/test-intelligence-platform"
    run(Path("harness"), repo)
