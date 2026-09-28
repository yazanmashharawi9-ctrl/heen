import { test } from "node:test";
import assert from "node:assert/strict";
import { isTimeZone, parseRegistration } from "./register.ts";

const ios = {
  token: "a".repeat(64),
  platform: "ios",
  apnsEnv: "sandbox",
  cell: "487-863",
  tz: "Asia/Amman",
  lang: "ar",
  types: ["RAIN_START", "THUNDER", "RAIN_START"],
  quietPreset: 1,
};

test("accepts a valid iOS registration and de-duplicates types", () => {
  const parsed = parseRegistration(ios);
  assert.ok(parsed.ok);
  assert.deepEqual(parsed.value.types, ["RAIN_START", "THUNDER"]);
  assert.equal(parsed.value.apnsEnv, "sandbox");
});

test("accepts a valid Android registration without apnsEnv", () => {
  const parsed = parseRegistration({ ...ios, platform: "android", apnsEnv: undefined, token: "fcm:APA91b" + "x".repeat(140) });
  assert.ok(parsed.ok);
  assert.equal(parsed.value.apnsEnv, null);
});

test("defaults: no types, quiet preset 1", () => {
  const parsed = parseRegistration({ ...ios, types: undefined, quietPreset: undefined });
  assert.ok(parsed.ok);
  assert.deepEqual(parsed.value.types, []);
  assert.equal(parsed.value.quietPreset, 1);
});

const bad: Array<[string, Record<string, unknown>]> = [
  ["non-hex APNs token", { token: "z".repeat(64) }],
  ["short APNs token", { token: "ab" }],
  ["iOS without apnsEnv", { apnsEnv: undefined }],
  ["unknown platform", { platform: "web" }],
  ["out-of-range cell", { cell: "999-9999" }],
  ["coordinates instead of a cell", { cell: "31.95,35.91" }],
  ["bad time zone", { tz: "Mars/Olympus" }],
  ["unsupported language", { lang: "fr" }],
  ["unknown event", { types: ["EARTHQUAKE"] }],
  ["bad quiet preset", { quietPreset: 7 }],
];
for (const [name, patch] of bad) {
  test(`rejects: ${name}`, () => {
    assert.equal(parseRegistration({ ...ios, ...patch }).ok, false);
  });
}

test("rejects non-objects", () => {
  assert.equal(parseRegistration(null).ok, false);
  assert.equal(parseRegistration("x").ok, false);
});

test("time zones", () => {
  assert.ok(isTimeZone("Europe/London"));
  assert.ok(isTimeZone("UTC"));
  assert.equal(isTimeZone(""), false);
  assert.equal(isTimeZone(42), false);
});
