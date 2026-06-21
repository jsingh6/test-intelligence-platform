# Test Intelligence Platform

A repo-native test intelligence system: a SwiftUI dummy app, a YAML behavior registry, and a Claude-powered agent pipeline that ties PRs → behaviors → test cases → regression coverage.

## Structure

```
App/                  SwiftUI iOS app (MVVM, feature-based folders)
harness/
  behaviors/          One YAML per feature area. Behavior registry. Versions with code.
  test-cases/         One YAML per feature area. Test case pool.
  audit/              gap_log.yaml — bug-to-gap audit trail (M4)
  reports/            Auto-generated release reports (M5)
agent/                Python pipeline modules (one file per concern)
scripts/              lint_test_ids.sh, submit_result.sh
.github/workflows/    pr_agent.yml, bug_agent.yml, release_report.yml
vscode-extension/     CodeLens overlay for @test-ids annotations
```

## Milestone status

| # | Name | Status |
|---|------|--------|
| M1 | Foundation — Dummy App + Behavior Registry | In progress |
| M2 | PR Agent — Context Gathering + Behavior Summary | Scaffolded |
| M3 | Test Case Generation + Pool Management | Scaffolded |
| M4 | Bug Loop + Regression Intelligence | Scaffolded |
| M5 | Release Readiness Dashboard + Automation Mapping | Scaffolded |

## Key conventions

### @test-ids annotations
Every public Swift function that implements user-facing behavior must have a `// @test-ids: TC001, TC002` comment on the preceding line.
The linter (`scripts/lint_test_ids.sh`) enforces this on changed files in a PR.

### Behavior IDs
Format: `<AREA>-B<NNN>` (e.g. `AUTH-B001`). Defined in `harness/behaviors/<area>.yaml`.

### Test Case IDs
Format: `<AREA>-TC<NNN>` (e.g. `AUTH-TC001`). Defined in `harness/test-cases/<area>_tc.yaml`.
Regression TCs use the `REG-` prefix.

### Priority
- P0 — must pass before any release (deploy gate blocked if failing)
- P1 — should pass; failure is a release risk
- P2 — nice to have
- P3 — low-risk edge case

## Running the agent locally

```bash
cp .env.example .env   # fill in ANTHROPIC_API_KEY, GITHUB_TOKEN
pip install -r requirements.txt
python -c "
from pathlib import Path
from agent.context_gather import gather
from agent.behavior_summary import generate
ctx = gather(PR_NUMBER, 'owner/repo', Path('harness'))
summary = generate(ctx)
print(summary.raw_summary)
"
```

## Submitting a manual test result

```bash
./scripts/submit_result.sh AUTH-TC001 pass
```

## Secrets required (GitHub repo settings)

| Secret | Used by |
|--------|---------|
| `ANTHROPIC_API_KEY` | behavior_summary.py, test_generator.py, regression_generator.py, semantic_mapper.py |
| `BOT_PAT` | bug_agent.yml (needs push permission) |

## iOS app: Xcode setup

The `App/` directory contains source files only. To create the Xcode project:
1. Open Xcode → File → New → Project → iOS App (SwiftUI, Swift)
2. Name it `TIP` (or your chosen name), targeting iOS 17+
3. Point the project root at this directory
4. Add all files under `App/` to the target
