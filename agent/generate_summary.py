"""Generate a GitHub Actions step summary from the TC pool YAMLs."""
from __future__ import annotations

import os
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import yaml

PRIORITY_ORDER = ["P0", "P1", "P2", "P3"]
STATUS_ICON = {"pass": "✅", "fail": "❌", None: "⬜"}
PRIORITY_LABEL = {
    "P0": "P0 — Deploy blockers",
    "P1": "P1 — Release risks",
    "P2": "P2 — Nice to have",
    "P3": "P3 — Edge cases",
}


def load_pool(harness_root: Path) -> list[dict]:
    cases = []
    for path in sorted((harness_root / "test-cases").glob("*.yaml")):
        if path.name.startswith("_"):
            continue
        data = yaml.safe_load(path.read_text()) or {}
        cases.extend(data.get("test_cases", []))
    return cases


def _pct(num: int, denom: int) -> str:
    return f"{round(num / denom * 100)}%" if denom else "—"


def _status_icon(tc: dict) -> str:
    return STATUS_ICON.get(tc.get("last_result"))


def _issue_link(tc: dict) -> str:
    url = tc.get("issue_url")
    if not url:
        return "—"
    num = url.rstrip("/").split("/")[-1]
    return f"[#{num}]({url})"


def render(cases: list[dict]) -> str:
    by_priority: dict[str, list[dict]] = defaultdict(list)
    for tc in cases:
        by_priority[tc.get("priority", "P3")].append(tc)

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines: list[str] = []

    lines.append("## Test Coverage Summary\n")
    lines.append(f"_Generated {now}_\n")

    # ── aggregate table ──────────────────────────────────────────────────────
    lines.append("| Priority | Total | ✅ Pass | ❌ Fail | ⬜ Not Run | Coverage |")
    lines.append("|----------|------:|-------:|-------:|----------:|----------|")

    totals = {"total": 0, "pass": 0, "fail": 0, "not_run": 0}
    for p in PRIORITY_ORDER:
        tcs = by_priority.get(p, [])
        passed = sum(1 for t in tcs if t.get("last_result") == "pass")
        failed = sum(1 for t in tcs if t.get("last_result") == "fail")
        not_run = len(tcs) - passed - failed
        coverage = _pct(passed, len(tcs))
        totals["total"] += len(tcs)
        totals["pass"] += passed
        totals["fail"] += failed
        totals["not_run"] += not_run
        lines.append(f"| {p} | {len(tcs)} | {passed} | {failed} | {not_run} | {coverage} |")

    t = totals
    overall = _pct(t["pass"], t["total"])
    lines.append(
        f"| **Total** | **{t['total']}** | **{t['pass']}** |"
        f" **{t['fail']}** | **{t['not_run']}** | **{overall}** |"
    )
    lines.append("")

    # ── per-priority detail ──────────────────────────────────────────────────
    for p in PRIORITY_ORDER:
        tcs = by_priority.get(p, [])
        if not tcs:
            continue
        label = PRIORITY_LABEL[p]

        # P0 always expanded; P1+ collapsed
        if p == "P0":
            lines.append(f"### {label}\n")
            lines.extend(_tc_table(tcs))
        else:
            passed = sum(1 for t in tcs if t.get("last_result") == "pass")
            lines.append(f"<details>")
            lines.append(
                f"<summary><strong>{label}</strong> — {len(tcs)} cases, "
                f"{passed} passing</summary>\n"
            )
            lines.extend(_tc_table(tcs))
            lines.append("</details>\n")

    return "\n".join(lines)


def _tc_table(tcs: list[dict]) -> list[str]:
    rows = ["| TC ID | Title | Status | Issue |", "|-------|-------|:------:|-------|"]
    for tc in tcs:
        tc_id = tc.get("id", "")
        title = tc.get("title", "").replace("|", "\\|")
        if len(title) > 70:
            title = title[:67] + "…"
        status = _status_icon(tc)
        issue = _issue_link(tc)
        rows.append(f"| `{tc_id}` | {title} | {status} | {issue} |")
    rows.append("")
    return rows


def main() -> None:
    harness_root = Path(os.environ.get("HARNESS_ROOT", "harness"))
    cases = load_pool(harness_root)
    if not cases:
        print("No test cases found.", file=sys.stderr)
        sys.exit(1)
    print(render(cases))


if __name__ == "__main__":
    main()
