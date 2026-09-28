// Bundles every moment into app/assets/content/moments.json for the Flutter app.
//
//   node tools/content/build.ts            # development bundle (drafts included, flagged)
//   node tools/content/build.ts --release  # refuses unless every moment is approved

import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { createHash } from "node:crypto";
import { APP_BUNDLE_PATH, canonicalize, relPath, type Json } from "./lib.ts";
import { validate } from "./validate.ts";

const release = process.argv.includes("--release");
const { errors, moments } = validate({ release });
if (errors.length) {
  for (const e of errors) console.error(`error: ${e}`);
  console.error("content has errors — nothing written");
  process.exit(1);
}

const bundled: Json[] = moments
  .map(({ data }) => {
    const copy = { ...data };
    delete copy.$schema;
    return copy;
  })
  .sort((a, b) => String((a as { id: string }).id).localeCompare(String((b as { id: string }).id)));

const contentHash = `sha256:${createHash("sha256").update(canonicalize(bundled)).digest("hex")}`;
const bundle = { format: 1, release, contentHash, moments: bundled };

mkdirSync(dirname(APP_BUNDLE_PATH), { recursive: true });
writeFileSync(APP_BUNDLE_PATH, `${JSON.stringify(bundle, null, 2)}\n`, "utf8");
console.log(`wrote ${bundled.length} moments to ${relPath(APP_BUNDLE_PATH)} (${contentHash.slice(0, 19)}…)`);
