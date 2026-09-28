import { test } from "node:test";
import assert from "node:assert/strict";
import { canonicalize, contentHash, loadMoments, type Moment, type MomentFile } from "./lib.ts";
import { validate, validateMoments } from "./validate.ts";

test("canonicalize sorts keys at every level", () => {
  assert.equal(canonicalize({ b: 1, a: { d: [2, { z: 1, y: 2 }], c: null } }), '{"a":{"c":null,"d":[2,{"y":2,"z":1}]},"b":1}');
});

test("contentHash ignores the review block and $schema, but not content", () => {
  const base = { id: "weather.x", title: { ar: "أ", en: "a" } };
  const withReview = { ...base, $schema: "x", review: { status: "approved", hash: "sha256:00" } };
  assert.equal(contentHash(base), contentHash(withReview));
  assert.notEqual(contentHash(base), contentHash({ ...base, title: { ar: "ب", en: "a" } }));
  assert.match(contentHash(base), /^sha256:[0-9a-f]{64}$/);
});

test("the real content validates in development mode", () => {
  assert.deepEqual(validate().errors, []);
});

// --- the validator must catch the mistakes that matter -------------------

function rain(): MomentFile {
  const real = loadMoments().find((m) => m.data.id === "weather.rain_start");
  assert.ok(real, "weather.rain_start fixture missing");
  return { ...real, data: structuredClone(real.data) };
}

function errorsFor(mutate: (m: Moment) => void, release = false): string[] {
  const file = rain();
  mutate(file.data);
  return validateMoments([file], { release }).errors;
}

const item = (m: Moment) => (m.items as Moment[])[0];
const source = (m: Moment) => (item(m).sources as Moment[])[0];

test("rejects a du'a without tashkeel", () => {
  const errors = errorsFor((m) => (item(m).ar = "اللهم صيبا نافعا"));
  assert.ok(errors.some((e) => e.includes("fully vocalised")), errors.join("\n"));
});

test("rejects a hadith source with no grading", () => {
  const errors = errorsFor((m) => (source(m).grades = []));
  assert.ok(errors.some((e) => e.includes("needs at least one grading")), errors.join("\n"));
});

test("rejects a weak du'a unless it is explicitly labelled", () => {
  const weak = (m: Moment) => (source(m).grades = [{ grade: "daif", by: "x" }]);
  assert.ok(errorsFor(weak).some((e) => e.includes("da'if")));
  assert.deepEqual(
    errorsFor((m) => {
      weak(m);
      item(m).showAsWeak = true;
    }),
    [],
  );
});

test("an approval is invalidated by any later edit", () => {
  const approve = (m: Moment) => (m.review = { status: "approved", reviewer: "R", date: "2026-10-01", hash: contentHash(m) });
  assert.deepEqual(errorsFor(approve, true), []);
  const errors = errorsFor((m) => {
    approve(m);
    item(m).tr = { en: "changed after review" };
  });
  assert.ok(errors.some((e) => e.includes("edited after approval")), errors.join("\n"));
});

test("release mode refuses drafts", () => {
  const errors = errorsFor(() => {}, true);
  assert.ok(errors.some((e) => e.includes("only approved moments can ship")), errors.join("\n"));
});

test("rejects over-long push text", () => {
  const errors = errorsFor((m) => ((m.push as Moment).title = { ar: "ط".repeat(80), en: "t" }));
  assert.ok(errors.some((e) => e.includes("push.title.ar")), errors.join("\n"));
});
