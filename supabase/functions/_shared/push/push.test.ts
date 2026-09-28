import { test } from "node:test";
import assert from "node:assert/strict";
import { base64url, importSigningKey, pemToPkcs8, signJwt } from "./jwt.ts";
import { buildApnsRequest, resetApnsJwtCache, sendApns, type ApnsConfig } from "./apns.ts";
import { buildFcmMessage, resetFcmTokenCache, sendFcm, type ServiceAccount } from "./fcm.ts";
import type { PushMessage } from "./message.ts";

const decoder = new TextDecoder();

function toPem(der: ArrayBuffer): string {
  const b64 = btoa(String.fromCharCode(...new Uint8Array(der)));
  return `-----BEGIN PRIVATE KEY-----\n${b64.match(/.{1,64}/g)!.join("\n")}\n-----END PRIVATE KEY-----\n`;
}

function fromBase64url(s: string): Uint8Array<ArrayBuffer> {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (s.length % 4)) % 4);
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

async function keyPair(alg: "ES256" | "RS256") {
  const params = alg === "ES256"
    ? { name: "ECDSA", namedCurve: "P-256" }
    : { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" };
  const pair = (await crypto.subtle.generateKey(params, true, ["sign", "verify"])) as CryptoKeyPair;
  return { pem: toPem(await crypto.subtle.exportKey("pkcs8", pair.privateKey)), publicKey: pair.publicKey };
}

async function verify(jwt: string, publicKey: CryptoKey, alg: "ES256" | "RS256"): Promise<boolean> {
  const [h, p, s] = jwt.split(".");
  return crypto.subtle.verify(
    alg === "ES256" ? { name: "ECDSA", hash: "SHA-256" } : { name: "RSASSA-PKCS1-v1_5" },
    publicKey,
    fromBase64url(s),
    new TextEncoder().encode(`${h}.${p}`),
  );
}

const message: PushMessage = {
  title: "يبدو أن المطر ينزل عندك",
  body: "«اللهم صيّبًا نافعًا»",
  momentId: "weather.rain_start",
  ttlSeconds: 2700,
  collapseKey: "RAIN_START_487-863",
};

test("base64url and PEM helpers", () => {
  assert.equal(base64url("\xff\xfe"), base64url(new Uint8Array([0xc3, 0xbf, 0xc3, 0xbe])));
  assert.equal(base64url(new Uint8Array([251, 255])), "-_8");
  assert.throws(() => pemToPkcs8("-----BEGIN PRIVATE KEY-----\n-----END PRIVATE KEY-----"));
});

for (const alg of ["ES256", "RS256"] as const) {
  test(`${alg} JWTs verify against the matching public key`, async () => {
    const { pem, publicKey } = await keyPair(alg);
    const jwt = await signJwt({ kid: "K" }, { iss: "T", iat: 1 }, await importSigningKey(pem, alg), alg);
    const [header, claims] = jwt.split(".").slice(0, 2).map((part) => JSON.parse(decoder.decode(fromBase64url(part))));
    assert.deepEqual(header, { kid: "K", alg, typ: "JWT" });
    assert.deepEqual(claims, { iss: "T", iat: 1 });
    assert.ok(await verify(jwt, publicKey, alg));
  });
}

test("service-account keys with literal \\n still import", async () => {
  const { pem } = await keyPair("RS256");
  await importSigningKey(pem.replace(/\n/g, "\\n"), "RS256");
});

test("APNs request shape", () => {
  const config: ApnsConfig = { teamId: "TEAM", keyId: "KEY", privateKeyPem: "", bundleId: "com.mashharawi.heen" };
  const { url, init } = buildApnsRequest("ab12", "sandbox", message, config, "JWT", 1000);
  assert.equal(url, "https://api.sandbox.push.apple.com/3/device/ab12");
  const headers = init.headers as Record<string, string>;
  assert.equal(headers.authorization, "bearer JWT");
  assert.equal(headers["apns-topic"], "com.mashharawi.heen");
  assert.equal(headers["apns-push-type"], "alert");
  assert.equal(headers["apns-expiration"], "3700");
  assert.equal(headers["apns-collapse-id"], "RAIN_START_487-863");
  const body = JSON.parse(init.body as string);
  assert.deepEqual(body.aps.alert, { title: message.title, body: message.body });
  assert.equal(body.moment, "weather.rain_start");
});

test("APNs: 200 is success, 410 marks the token dead", async () => {
  resetApnsJwtCache();
  const { pem } = await keyPair("ES256");
  const config: ApnsConfig = { teamId: "TEAM", keyId: "KEY", privateKeyPem: pem, bundleId: "com.mashharawi.heen" };
  const ok = await sendApns("t", "production", message, config, async () => new Response(null, { status: 200 }));
  assert.deepEqual(ok, { ok: true });
  const dead = await sendApns("t", "production", message, config, async () =>
    Response.json({ reason: "Unregistered" }, { status: 410 }));
  assert.deepEqual(dead, { ok: false, unregistered: true, status: 410, reason: "Unregistered" });
  const busy = await sendApns("t", "production", message, config, async () =>
    Response.json({ reason: "TooManyRequests" }, { status: 429 }));
  assert.equal(busy.ok, false);
  assert.equal(!busy.ok && busy.unregistered, false);
});

test("FCM message shape", () => {
  const m = buildFcmMessage("tok", message).message as Record<string, any>;
  assert.equal(m.token, "tok");
  assert.deepEqual(m.data, { moment: "weather.rain_start" });
  assert.equal(m.android.ttl, "2700s");
  assert.equal(m.android.collapse_key, "RAIN_START_487-863");
  assert.deepEqual(m.android.notification, { channel_id: "moments", tag: "RAIN_START_487-863" });
});

test("FCM: exchanges the service-account JWT, sends, and flags dead tokens", async () => {
  resetFcmTokenCache();
  const { pem } = await keyPair("RS256");
  const account: ServiceAccount = { project_id: "heen-push", client_email: "push@heen.iam", private_key: pem };
  const calls: Array<{ url: string; init: RequestInit }> = [];
  const fetcher = async (url: string, init: RequestInit) => {
    calls.push({ url, init });
    if (url.startsWith("https://oauth2.googleapis.com/")) return Response.json({ access_token: "AT", expires_in: 3600 });
    return calls.length === 2
      ? Response.json({ name: "projects/heen-push/messages/1" })
      : Response.json({ error: { status: "NOT_FOUND", message: "gone", details: [{ errorCode: "UNREGISTERED" }] } }, { status: 404 });
  };

  assert.deepEqual(await sendFcm("tok", message, account, fetcher), { ok: true });
  const grant = new URLSearchParams(calls[0].init.body as string);
  assert.equal(grant.get("grant_type"), "urn:ietf:params:oauth:grant-type:jwt-bearer");
  assert.equal(grant.get("assertion")!.split(".").length, 3);
  assert.equal(calls[1].url, "https://fcm.googleapis.com/v1/projects/heen-push/messages:send");
  assert.equal((calls[1].init.headers as Record<string, string>).authorization, "Bearer AT");

  const dead = await sendFcm("tok", message, account, fetcher);
  assert.equal(calls.length, 3, "the OAuth token is cached between sends");
  assert.deepEqual(dead, { ok: false, unregistered: true, status: 404, reason: "UNREGISTERED: gone" });
});
