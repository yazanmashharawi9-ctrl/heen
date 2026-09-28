// Sends pushes. Secret key only — never callable from the app.
//
// M0 (now): POST { token, platform, apnsEnv?, title?, body? } sends one test
// push, to prove APNs-over-HTTP/2 and FCM v1 work from the Edge Runtime.
// M2: drains the notification queue in batches of ~500 devices.
//
// Secrets (supabase secrets set …):
//   APNS_TEAM_ID, APNS_KEY_ID, APNS_PRIVATE_KEY (contents of the .p8), APNS_BUNDLE_ID
//   FCM_SERVICE_ACCOUNT (the service-account JSON, Android only)

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { sendApns, type ApnsConfig } from "../_shared/push/apns.ts";
import { sendFcm, type ServiceAccount } from "../_shared/push/fcm.ts";
import type { PushMessage } from "../_shared/push/message.ts";

function apnsConfig(): ApnsConfig | undefined {
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const keyId = Deno.env.get("APNS_KEY_ID");
  const privateKeyPem = Deno.env.get("APNS_PRIVATE_KEY");
  if (!teamId || !keyId || !privateKeyPem) return undefined;
  return { teamId, keyId, privateKeyPem, bundleId: Deno.env.get("APNS_BUNDLE_ID") ?? "com.mashharawi.heen" };
}

function fcmAccount(): ServiceAccount | undefined {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  return raw ? (JSON.parse(raw) as ServiceAccount) : undefined;
}

export default {
  fetch: withSupabase({ auth: "secret" }, async (req) => {
    if (req.method !== "POST") return Response.json({ error: "POST only" }, { status: 405 });
    const b = (await req.json().catch(() => ({}))) as Record<string, string | undefined>;
    if (!b.token) return Response.json({ error: "token required" }, { status: 400 });

    const message: PushMessage = {
      title: b.title ?? "حِين · Heen",
      body: b.body ?? "إشعار تجريبي — test notification",
      momentId: "weather.rain_start",
      ttlSeconds: 600,
    };

    if (b.platform === "ios") {
      const config = apnsConfig();
      if (!config) return Response.json({ error: "APNs secrets are not set" }, { status: 500 });
      const env = b.apnsEnv === "production" ? "production" : "sandbox";
      return Response.json(await sendApns(b.token, env, message, config));
    }
    if (b.platform === "android") {
      const account = fcmAccount();
      if (!account) return Response.json({ error: "FCM_SERVICE_ACCOUNT is not set" }, { status: 500 });
      return Response.json(await sendFcm(b.token, message, account));
    }
    return Response.json({ error: "platform must be ios or android" }, { status: 400 });
  }),
};
