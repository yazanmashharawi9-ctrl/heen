// A push as the backend thinks about it, before it is shaped for APNs or FCM.

export interface PushMessage {
  title: string;
  body: string;
  /** Moment to open when the notification is tapped, e.g. "weather.rain_start". */
  momentId: string;
  /** Seconds after which an undelivered push is dropped — a rain alert is useless an hour late. */
  ttlSeconds: number;
  /** Replaces an earlier notification with the same key instead of stacking, e.g. "RAIN_START_487-863". */
  collapseKey?: string;
}

export type SendResult =
  | { ok: true }
  /** The token is dead (app uninstalled, token rotated) — delete the device row. */
  | { ok: false; unregistered: true; status: number; reason: string }
  | { ok: false; unregistered: false; status: number; reason: string };

export type Fetcher = (input: string, init: RequestInit) => Promise<Response>;
