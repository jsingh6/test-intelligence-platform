/**
 * M5: VS Code CodeLens extension — shows test case pass/fail status
 * inline next to @test-ids annotations in Swift files.
 */
import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";

interface TestCase {
  id: string;
  title: string;
  last_result: "pass" | "fail" | null;
  last_run_date: string | null;
}

export function activate(context: vscode.ExtensionContext): void {
  context.subscriptions.push(
    vscode.languages.registerCodeLensProvider(
      { language: "swift" },
      new TestIdLensProvider()
    )
  );
}

export function deactivate(): void {}

class TestIdLensProvider implements vscode.CodeLensProvider {
  provideCodeLenses(document: vscode.TextDocument): vscode.CodeLens[] {
    const pool = loadPool(document.uri.fsPath);
    const lenses: vscode.CodeLens[] = [];

    for (let i = 0; i < document.lineCount; i++) {
      const line = document.lineAt(i).text;
      const match = line.match(/@test-ids:\s*(.+)/);
      if (!match) continue;

      const tcIds = match[1].split(",").map((s) => s.trim());
      for (const tcId of tcIds) {
        const tc = pool[tcId];
        if (!tc) continue;

        const range = new vscode.Range(i, 0, i, 0);
        const icon = tc.last_result === "pass" ? "✅" : tc.last_result === "fail" ? "🔴" : "⚪";
        const label = `${icon} ${tcId}: ${tc.title}${tc.last_run_date ? ` (${tc.last_run_date})` : ""}`;

        lenses.push(
          new vscode.CodeLens(range, {
            title: label,
            command: "tip.openTestCase",
            arguments: [tcId],
          })
        );
      }
    }
    return lenses;
  }
}

function loadPool(filePath: string): Record<string, TestCase> {
  const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!workspaceRoot) return {};

  const harnessDir = path.join(workspaceRoot, "harness", "test-cases");
  if (!fs.existsSync(harnessDir)) return {};

  const pool: Record<string, TestCase> = {};
  for (const yamlFile of fs.readdirSync(harnessDir)) {
    if (!yamlFile.endsWith(".yaml") || yamlFile.startsWith("_")) continue;
    const content = fs.readFileSync(path.join(harnessDir, yamlFile), "utf-8");
    const data = yaml.load(content) as { test_cases: TestCase[] };
    for (const tc of data?.test_cases ?? []) {
      pool[tc.id] = tc;
    }
  }
  return pool;
}
