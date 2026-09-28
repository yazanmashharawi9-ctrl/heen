// Records a reviewer's decision on a moment.
//
//   node tools/content/review.ts approve  <id> --reviewer "Sheikh …"
//   node tools/content/review.ts status   <id> in_review|changes_requested|draft [--notes "…"]
//   node tools/content/review.ts list
//
// `approve` stamps today's date and the content hash, so any later edit to the
// moment is caught by the validator and the moment goes back for review.

import { contentHash, loadMoments, writeMoment, type Json } from "./lib.ts";

const STATUSES = ["draft", "in_review", "changes_requested"];

function flag(name: string): string | undefined {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 ? process.argv[i + 1] : undefined;
}

function fail(message: string): never {
  console.error(message);
  process.exit(1);
}

const [command, id, value] = process.argv.slice(2);
const moments = loadMoments();

if (command === "list") {
  for (const { data } of moments) {
    const review = data.review as { [k: string]: Json };
    console.log(`${String(review.status).padEnd(18)} ${data.id}${review.reviewer ? `  (${review.reviewer})` : ""}`);
  }
  process.exit(0);
}

const file = moments.find((m) => m.data.id === id);
if (!file) fail(`no moment with id "${id}"`);

if (command === "approve") {
  const reviewer = flag("reviewer");
  if (!reviewer) fail('approve needs --reviewer "<name>"');
  const date = new Date().toISOString().slice(0, 10);
  file.data.review = { status: "approved", reviewer, date, hash: contentHash(file.data) };
  const notes = flag("notes");
  if (notes) (file.data.review as { [k: string]: Json }).notes = notes;
} else if (command === "status") {
  if (!value || !STATUSES.includes(value)) fail(`status must be one of: ${STATUSES.join(", ")}`);
  file.data.review = { status: value };
  const notes = flag("notes");
  if (notes) (file.data.review as { [k: string]: Json }).notes = notes;
} else {
  fail("usage: review.ts approve <id> --reviewer <name> | status <id> <status> | list");
}

writeMoment(file.path, file.data);
console.log(`${id}: ${(file.data.review as { status: string }).status}`);
