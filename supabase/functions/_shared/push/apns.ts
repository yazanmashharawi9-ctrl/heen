// Apple Push Notification service, called directly — no Firebase on iOS.
// Token-based auth: an ES256 JWT signed with the team's APNs .p8 key.
// https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns

import { importSigningKey, signJwt } from "./jwt.ts";
import type { Fetcher, PushMessage, SendResult } from "./message.ts";

export interface ApnsConfig {
  teamId: string;
  keyId: string;
  /** Contents of AuthKey_<keyId>.p8. */
  privateKeyPem: string;
  /** apns-topic: the app's bundle id. */
  bundleId: string;
}

export type ApnsEnv = "sandbox" | "production";

const HOSTS: Record<ApnsEnv, string> = {
  sandbox: "https://api.sandbox.push.apple.com",
  production: "https://api.push.apple.com",
};

// Apple rejects tokens refreshed more often than every 20 minutes and older
// than an hour; 50 minutes sits safely between.
const TOKEN_LIFETIME_S = 50 * 60;
let cached: { jwt: string; issuedAt: number; keyId: string } | undefined;

export async function apnsJwt(config: ApnsConfig, nowS = Math.floor(Date.now() / 1000)): Promise<string> {
  if (cached && cached.keyId === config.keyId && nowS - cached.issuedAt < TOKEN_LIFETIME_S) return cached.jwt;
  const key = await importSigningKey(config.privateKeyPem, "ES256");
  const jwt = await signJwt({ kid: config.keyId }, { iss: config.teamId, iat: nowS }, key, "ES256");
  cached = { jwt, issuedAt: nowS, keyId: config.keyId };
  return jwt;
}

export function buildApnsRequest(
  token: string,
  env: ApnsEnv,
  message: PushMessage,
  config: ApnsConfig,
  jwt: string,
  nowS = Math.floor(Date.now() / 1000),
): { url: string; init: RequestInit } {
  const headers: Record<string, string> = {
    authorization: `bearer ${jwt}`,
    "apns-topic": config.bundleId,
    "apns-push-type": "alert",
    "apns-priority": "10",
    "apns-expiration": String(nowS + message.ttlSeconds),
    "content-type": "application/json",
  };
  if (message.collapseKey) headers["apns-collapse-id"] = message.collapseKey.slice(0, 64);

  const payload = {
    aps: {
      alert: { title: message.title, body: message.body },
      sound: "default",
      "thread-id": message.momentId,
    },
    moment: message.momentId,
  };
  return { url: `${HOSTS[env]}/3/device/${token}`, init: { method: "POST", headers, body: JSON.stringify(payload) } };
}

// Reasons after which the token will never work again.
const DEAD_TOKEN_REASONS = new Set(["BadDeviceToken", "Unregistered", "DeviceTokenNotForTopic"]);

export async function sendApns(
  token: string,
  env: ApnsEnv,
  message: PushMessage,
  config: ApnsConfig,
  fetcher: Fetcher = fetch,
): Promise<SendResult> {
  const { url, init } = buildApnsRequest(token, env, message, config, await apnsJwt(config));
  const res = await fetcher(url, init);
  if (res.status === 200) return { ok: true };
  let reason = res.statusText;
  try {
    reason = ((await res.json()) as { reason?: string }).reason ?? reason;
  } catch {
    // body is optional
  }
  const unregistered = res.status === 410 || DEAD_TOKEN_REASONS.has(reason);
  return { ok: false, unregistered, status: res.status, reason };
}

/** Test hook: forget the cached provider token. */
export function resetApnsJwtCache(): void {
  cached = undefined;
}
