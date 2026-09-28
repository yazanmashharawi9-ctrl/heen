// Firebase Cloud Messaging HTTP v1 — used for Android only, purely as the
// delivery pipe. No other Firebase product is involved.
// https://firebase.google.com/docs/cloud-messaging/send/v1-api

import { importSigningKey, signJwt } from "./jwt.ts";
import type { Fetcher, PushMessage, SendResult } from "./message.ts";

/** The fields we use from a Google service-account JSON key. */
export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
/** Android notification channel the app creates for moment notifications. */
export const ANDROID_CHANNEL_ID = "moments";

let cached: { accessToken: string; expiresAt: number; email: string } | undefined;

export async function fcmAccessToken(
  account: ServiceAccount,
  fetcher: Fetcher = fetch,
  nowS = Math.floor(Date.now() / 1000),
): Promise<string> {
  if (cached && cached.email === account.client_email && nowS < cached.expiresAt - 300) return cached.accessToken;
  const key = await importSigningKey(account.private_key, "RS256");
  const assertion = await signJwt(
    {},
    { iss: account.client_email, scope: SCOPE, aud: TOKEN_URL, iat: nowS, exp: nowS + 3600 },
    key,
    "RS256",
  );
  const res = await fetcher(TOKEN_URL, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }).toString(),
  });
  if (!res.ok) throw new Error(`google oauth failed: ${res.status} ${await res.text()}`);
  const { access_token, expires_in } = (await res.json()) as { access_token: string; expires_in: number };
  cached = { accessToken: access_token, expiresAt: nowS + expires_in, email: account.client_email };
  return access_token;
}

export function buildFcmMessage(token: string, message: PushMessage): Record<string, unknown> {
  return {
    message: {
      token,
      notification: { title: message.title, body: message.body },
      data: { moment: message.momentId },
      android: {
        priority: "HIGH",
        ttl: `${message.ttlSeconds}s`,
        ...(message.collapseKey ? { collapse_key: message.collapseKey } : {}),
        notification: {
          channel_id: ANDROID_CHANNEL_ID,
          ...(message.collapseKey ? { tag: message.collapseKey } : {}),
        },
      },
    },
  };
}

export async function sendFcm(
  token: string,
  message: PushMessage,
  account: ServiceAccount,
  fetcher: Fetcher = fetch,
): Promise<SendResult> {
  const accessToken = await fcmAccessToken(account, fetcher);
  const res = await fetcher(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
    method: "POST",
    headers: { authorization: `Bearer ${accessToken}`, "content-type": "application/json" },
    body: JSON.stringify(buildFcmMessage(token, message)),
  });
  if (res.ok) return { ok: true };
  let reason = res.statusText;
  let errorCode = "";
  try {
    const body = (await res.json()) as {
      error?: { status?: string; message?: string; details?: Array<{ errorCode?: string }> };
    };
    reason = body.error?.message ?? reason;
    errorCode = body.error?.details?.find((d) => d.errorCode)?.errorCode ?? body.error?.status ?? "";
  } catch {
    // keep statusText
  }
  const unregistered = res.status === 404 || errorCode === "UNREGISTERED";
  return { ok: false, unregistered, status: res.status, reason: errorCode ? `${errorCode}: ${reason}` : reason };
}

/** Test hook: forget the cached OAuth token. */
export function resetFcmTokenCache(): void {
  cached = undefined;
}
