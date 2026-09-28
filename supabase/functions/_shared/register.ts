// Validation for POST /api/register — kept free of Deno APIs so it is
// unit-tested under Node. Everything the app sends is checked here before it
// touches the database.

import { parseCellId } from "./geo/cell.ts";
import { isWeatherEvent, type WeatherEvent } from "./weather/events.ts";

export interface Registration {
  token: string;
  platform: "ios" | "android";
  apnsEnv: "sandbox" | "production" | null;
  cell: string;
  tz: string;
  lang: "ar" | "en";
  types: WeatherEvent[];
  quietPreset: 0 | 1 | 2;
}

export type Parsed<T> = { ok: true; value: T } | { ok: false; error: string };

const APNS_TOKEN = /^[0-9a-f]{64,200}$/i;
const FCM_TOKEN = /^[A-Za-z0-9_:\-]{20,4096}$/;

export function isTimeZone(tz: unknown): tz is string {
  if (typeof tz !== "string" || tz.length > 64) return false;
  try {
    new Intl.DateTimeFormat("en", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

export function parseRegistration(input: unknown): Parsed<Registration> {
  if (!input || typeof input !== "object") return { ok: false, error: "body must be a JSON object" };
  const b = input as Record<string, unknown>;

  const platform = b.platform;
  if (platform !== "ios" && platform !== "android") return { ok: false, error: "platform must be ios or android" };

  const token = b.token;
  if (typeof token !== "string" || !(platform === "ios" ? APNS_TOKEN : FCM_TOKEN).test(token)) {
    return { ok: false, error: `token is not a valid ${platform === "ios" ? "APNs" : "FCM"} token` };
  }

  let apnsEnv: Registration["apnsEnv"] = null;
  if (platform === "ios") {
    if (b.apnsEnv !== "sandbox" && b.apnsEnv !== "production") {
      return { ok: false, error: "apnsEnv must be sandbox or production for ios" };
    }
    apnsEnv = b.apnsEnv;
  }

  if (typeof b.cell !== "string" || !parseCellId(b.cell)) return { ok: false, error: "cell is not a valid cell id" };
  if (!isTimeZone(b.tz)) return { ok: false, error: "tz is not an IANA time zone" };
  if (b.lang !== "ar" && b.lang !== "en") return { ok: false, error: "lang must be ar or en" };

  const types = b.types ?? [];
  if (!Array.isArray(types) || !types.every(isWeatherEvent)) return { ok: false, error: "types contains an unknown event" };

  const quietPreset = b.quietPreset ?? 1;
  if (quietPreset !== 0 && quietPreset !== 1 && quietPreset !== 2) return { ok: false, error: "quietPreset must be 0, 1 or 2" };

  return {
    ok: true,
    value: {
      token,
      platform,
      apnsEnv,
      cell: b.cell,
      tz: b.tz,
      lang: b.lang,
      types: [...new Set(types)],
      quietPreset,
    },
  };
}
