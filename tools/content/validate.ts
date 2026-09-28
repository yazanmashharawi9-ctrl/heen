// Validates every moment under content/moments.
//
//   node tools/content/validate.ts            # development: drafts allowed
//   node tools/content/validate.ts --release  # release: every moment must be approved
//
// Exit code 1 on any error. The release build runs the --release form, so an
// unreviewed or edited-after-approval moment can never ship.

import { readFileSync } from "node:fs";
// ajv is CommonJS: take the named class, and the plugin from `.default`
// (what Node's ESM interop and TypeScript's nodenext both agree on).
import { Ajv2020, type ValidateFunction } from "ajv/dist/2020.js";
import ajvFormats from "ajv-formats";
import { SCHEMA_PATH, contentHash, loadMoments, loadPeople, type Json, type MomentFile } from "./lib.ts";

const PUSH_TITLE_MAX = 65;
const PUSH_BODY_MAX = 180;
const HARAKAT = /[\u064B-\u0652]/;
const ARABIC_LETTER = /[\u0621-\u064A]/;
const GRADE_RANK: Record<string, number> = {
  sahih: 4,
  hasan: 3,
  sahih_li_ghayrihi: 3,
  hasan_li_ghayrihi: 2,
  daif: 0,
};

export interface Report {
  errors: string[];
  warnings: string[];
  moments: MomentFile[];
}

type Obj = { [key: string]: Json };
const obj = (v: Json | undefined): Obj => (v && typeof v === "object" && !Array.isArray(v) ? v : {});
const arr = (v: Json | undefined): Json[] => (Array.isArray(v) ? v : []);
const str = (v: Json | undefined): string => (typeof v === "string" ? v : "");
const length = (s: string): number => [...s].length;

function checkSources(where: string, sources: Json[], errors: string[], people: Record<string, string>): number {
  let best = -1;
  for (const [i, s] of sources.entries()) {
    const source = obj(s);
    const grades = arr(source.grades);
    const names = [str(source.narrator), ...grades.map((g) => str(obj(g).by))].filter(Boolean);
    for (const name of names) {
      if (!(name in people)) errors.push(`${where}.sources[${i}]: "${name}" has no Arabic name in content/glossary.json`);
    }
    if (source.type === "quran") {
      best = Math.max(best, 5);
      continue;
    }
    if (grades.length === 0) {
      errors.push(`${where}.sources[${i}]: a non-Qur'an source needs at least one grading`);
      continue;
    }
    for (const g of grades) best = Math.max(best, GRADE_RANK[str(obj(g).grade)] ?? -1);
  }
  return best;
}

let compiled: ValidateFunction | undefined;
function schemaCheck(): ValidateFunction {
  if (!compiled) {
    const ajv = new Ajv2020({ allErrors: true, strict: true });
    ajvFormats.default(ajv);
    compiled = ajv.compile(JSON.parse(readFileSync(SCHEMA_PATH, "utf8")));
  }
  return compiled;
}

export function validate({ release = false } = {}): Report {
  return validateMoments(loadMoments(), { release });
}

export function validateMoments(
  moments: MomentFile[],
  { release = false, people = loadPeople() }: { release?: boolean; people?: Record<string, string> } = {},
): Report {
  const errors: string[] = [];
  const warnings: string[] = [];
  const check = schemaCheck();
  const ids = new Map<string, string>();
  const slugs = new Map<string, string>();

  for (const file of moments) {
    const m = file.data;
    const at = file.rel;

    if (!check(m)) {
      for (const e of check.errors ?? []) errors.push(`${at}: ${e.instancePath || "/"} ${e.message}`);
      continue; // the checks below assume the shape is right
    }

    const id = str(m.id);
    const category = str(m.category);
    if (!file.rel.endsWith(`/${category}/${id}.json`)) {
      errors.push(`${at}: must live at content/moments/${category}/${id}.json`);
    }
    if (!id.startsWith(`${category}.`)) errors.push(`${at}: id must start with "${category}."`);
    if (ids.has(id)) errors.push(`${at}: duplicate id "${id}" (also in ${ids.get(id)})`);
    ids.set(id, at);

    const slug = obj(obj(m.share).slug);
    for (const lang of ["ar", "en"]) {
      const s = str(slug[lang]);
      if (!s) continue;
      const key = `${lang}:${s}`;
      if (slugs.has(key)) errors.push(`${at}: share slug "${s}" already used by ${slugs.get(key)}`);
      slugs.set(key, at);
    }

    const push = obj(m.push);
    for (const lang of ["ar", "en"]) {
      const title = str(obj(push.title)[lang]);
      const body = str(obj(push.body)[lang]);
      if (length(title) > PUSH_TITLE_MAX) errors.push(`${at}: push.title.${lang} is over ${PUSH_TITLE_MAX} characters`);
      if (length(body) > PUSH_BODY_MAX) errors.push(`${at}: push.body.${lang} is over ${PUSH_BODY_MAX} characters`);
    }

    for (const [i, it] of arr(m.items).entries()) {
      const item = obj(it);
      const where = `${at}: items[${i}]`;
      const kind = str(item.kind);
      const ar = str(item.ar);
      if (!ARABIC_LETTER.test(ar)) errors.push(`${where}.ar has no Arabic text`);
      if ((kind === "dua" || kind === "dhikr" || kind === "quran") && !HARAKAT.test(ar)) {
        errors.push(`${where}.ar must be fully vocalised (${kind})`);
      }
      if ((kind === "dua" || kind === "dhikr") && !item.translit) {
        warnings.push(`${where}: ${kind} without a transliteration — new Muslims rely on it`);
      }
      if (!item.newMuslim) warnings.push(`${where}: no newMuslim explanation`);

      const best = checkSources(where, arr(item.sources), errors, people);
      if (best === GRADE_RANK.daif && item.showAsWeak !== true) {
        errors.push(`${where}: best grading is da'if — remove it or set showAsWeak so the UI labels it`);
      }
    }

    for (const [i, note] of arr(m.fiqh).entries()) {
      checkSources(`${at}: fiqh[${i}]`, arr(obj(note).sources), errors, people);
    }

    const review = obj(m.review);
    const status = str(review.status);
    if (status === "approved") {
      if (!review.reviewer || !review.date || !review.hash) {
        errors.push(`${at}: approved moments need reviewer, date and hash (use content:review approve)`);
      } else if (review.hash !== contentHash(m)) {
        errors.push(`${at}: edited after approval — the approved hash no longer matches, send it back for review`);
      }
    } else if (release) {
      errors.push(`${at}: status is "${status}" — only approved moments can ship`);
    }
  }

  return { errors, warnings, moments };
}

if (import.meta.main) {
  const release = process.argv.includes("--release");
  const { errors, warnings, moments } = validate({ release });
  for (const w of warnings) console.warn(`warning: ${w}`);
  for (const e of errors) console.error(`error: ${e}`);
  const approved = moments.filter((m) => obj(m.data.review).status === "approved").length;
  console.log(
    `${moments.length} moments, ${approved} approved, ${errors.length} errors, ${warnings.length} warnings` +
      (release ? " (release mode)" : ""),
  );
  process.exit(errors.length ? 1 : 0);
}
