// Rewrites every moment file in the one canonical layout (2-space JSON,
// trailing newline) so review diffs only ever show real changes.
//
//   node tools/content/format.ts          # rewrite files
//   node tools/content/format.ts --check  # exit 1 if any file is not formatted

import { readFileSync } from "node:fs";
import { loadMoments, writeMoment } from "./lib.ts";

const checkOnly = process.argv.includes("--check");
const unformatted: string[] = [];

for (const file of loadMoments()) {
  const want = `${JSON.stringify(file.data, null, 2)}\n`;
  if (readFileSync(file.path, "utf8") === want) continue;
  unformatted.push(file.rel);
  if (!checkOnly) writeMoment(file.path, file.data);
}

if (checkOnly && unformatted.length) {
  for (const rel of unformatted) console.error(`not formatted: ${rel}`);
  console.error("run: npm run content:format");
  process.exit(1);
}
console.log(checkOnly ? "all moment files formatted" : `formatted ${unformatted.length} file(s)`);
