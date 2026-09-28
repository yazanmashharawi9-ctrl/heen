// Called by Supabase Cron every 10 minutes (secret key only).
//
// M2: pick cells whose next_poll is due, fetch MET Norway (+ METAR, with
// Open-Meteo as fallback), run the transition rules in _shared/rules, record
// events, and enqueue notification batches for `send`. Also releases the
// morning digest for devices whose quiet hours just ended.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

export default {
  fetch: withSupabase({ auth: "secret" }, async () => {
    return Response.json({ ok: true, processed: 0, note: "weather pipeline arrives in M2" });
  }),
};
