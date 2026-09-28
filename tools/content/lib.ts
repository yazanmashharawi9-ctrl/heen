// Shared helpers for the content tools. Plain TypeScript with only erasable
// syntax, so Node 24 runs it directly (no build step).

import { createHash } from "node:crypto";
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
export const MOMENTS_DIR = join(ROOT, "content", "moments");
export const SCHEMA_PATH = join(ROOT, "content", "schema", "moment.schema.json");
export const APP_BUNDLE_PATH = join(ROOT, "app", "assets", "content", "moments.json");
export const GLOSSARY_PATH = join(ROOT, "content", "glossary.json");

export type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
export type Moment = { [key: string]: Json };

export interface MomentFile {
  path: string;
  /** Path relative to the repo root, always with forward slashes. */
  rel: string;
  data: Moment;
}

export function listMomentFiles(dir: string = MOMENTS_DIR): string[] {
  const out: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...listMomentFiles(full));
    else if (entry.isFile() && entry.name.endsWith(".json")) out.push(full);
  }
  return out.sort();
}

export function relPath(path: string): string {
  return relative(ROOT, path).split(sep).join("/");
}

export function loadMoments(): MomentFile[] {
  return listMomentFiles().map((path) => {
    const raw = readFileSync(path, "utf8");
    try {
      return { path, rel: relPath(path), data: JSON.parse(raw) as Moment };
    } catch (error) {
      throw new Error(`${relPath(path)}: invalid JSON — ${(error as Error).message}`);
    }
  });
}

/** JSON with object keys sorted at every level, no whitespace. */
export function canonicalize(value: Json): string {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(canonicalize).join(",")}]`;
  const keys = Object.keys(value).sort();
  return `{${keys.map((k) => `${JSON.stringify(k)}:${canonicalize(value[k])}`).join(",")}}`;
}

/**
 * Hash of everything a reviewer approves: the whole moment except the review
 * block itself and the editor-only $schema pointer. Any edit to the text,
 * sources, fiqh notes, push wording or trigger changes the hash and so
 * invalidates an earlier approval.
 */
export function contentHash(moment: Moment): string {
  const copy: Moment = { ...moment };
  delete copy.review;
  delete copy.$schema;
  return `sha256:${createHash("sha256").update(canonicalize(copy)).digest("hex")}`;
}

/** Latin name used in sources → Arabic name (content/glossary.json). */
export function loadPeople(): Record<string, string> {
  const raw = JSON.parse(readFileSync(GLOSSARY_PATH, "utf8")) as { people: Record<string, { ar: string }> };
  return Object.fromEntries(Object.entries(raw.people).map(([name, v]) => [name, v.ar]));
}

export function writeMoment(path: string, data: Moment): void {
  writeFileSync(path, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}
