// Public API the app talks to, authenticated with the publishable key
// (apikey header). All database access goes through ctx.supabaseAdmin —
// clients have no table access of their own (see the init migration).
//
//   GET    /api/health
//   POST   /api/register     device token + cell + preferences (also a cell ping)
//   DELETE /api/register     { token } — the user turned weather moments off
//
// Planned: /said, /count (M2), /calendar (M4), /sky (M5), /feedback (M2).

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { cellCenter } from "../_shared/geo/cell.ts";
import { parseRegistration } from "../_shared/register.ts";

const json = (body: unknown, status = 200) => Response.json(body, { status });

async function readJson(req: Request): Promise<unknown> {
  try {
    return await req.json();
  } catch {
    return undefined;
  }
}

export default {
  fetch: withSupabase({ auth: "publishable" }, async (req, ctx) => {
    const route = new URL(req.url).pathname.replace(/^.*?\/api(?=\/|$)/, "") || "/";
    const db = ctx.supabaseAdmin;

    if (route === "/health" && req.method === "GET") return json({ ok: true });

    if (route === "/register" && req.method === "POST") {
      const parsed = parseRegistration(await readJson(req));
      if (!parsed.ok) return json({ error: parsed.error }, 400);
      const r = parsed.value;
      const now = new Date().toISOString();

      const { lat, lon } = cellCenter(r.cell);
      const cell = await db.from("cells").upsert({ id: r.cell, lat, lon, tz: r.tz, last_ping: now }, { onConflict: "id" });
      if (cell.error) return json({ error: "could not save cell" }, 500);

      const device = await db.from("devices").upsert(
        {
          token: r.token,
          platform: r.platform,
          apns_env: r.apnsEnv,
          cell: r.cell,
          lang: r.lang,
          types: r.types,
          quiet_preset: r.quietPreset,
          tz: r.tz,
          updated_at: now,
        },
        { onConflict: "token" },
      );
      if (device.error) return json({ error: "could not save device" }, 500);
      return json({ ok: true });
    }

    if (route === "/register" && req.method === "DELETE") {
      const body = (await readJson(req)) as { token?: unknown } | undefined;
      if (typeof body?.token !== "string" || body.token.length > 4096) return json({ error: "token required" }, 400);
      const { error } = await db.from("devices").delete().eq("token", body.token);
      if (error) return json({ error: "could not delete device" }, 500);
      return json({ ok: true });
    }

    return json({ error: "not found" }, 404);
  }),
};
