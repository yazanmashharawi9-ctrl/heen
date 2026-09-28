-- Heen backend schema.
--
-- Clients never touch these tables: RLS is enabled with no policies, and the
-- anon/authenticated roles are revoked. Only Edge Functions, through the
-- secret key (ctx.supabaseAdmin), read and write.
--
-- Privacy: nothing here identifies a person. A device row is a push token, a
-- coarse ~25 km cell, a language and notification preferences — no location,
-- no account, no IP address.

-- ---------------------------------------------------------------------------
-- Weather cells: a 0.25° grid. id = "<latIndex>-<lonIndex>", see
-- supabase/functions/_shared/geo/cell.ts (and app/lib/core/geo_cell.dart).
-- ---------------------------------------------------------------------------
create table public.cells (
  id text primary key check (id ~ '^[0-9]{1,3}-[0-9]{1,4}$'),
  lat double precision not null check (lat between -90 and 90),     -- cell centre
  lon double precision not null check (lon between -180 and 180),
  tz text not null,                                                  -- IANA zone reported by devices
  last_ping timestamptz not null default now(),                      -- a device registered here recently
  next_poll timestamptz not null default now(),                      -- when tick should fetch weather again
  state jsonb not null default '{}'::jsonb                           -- rule state: dry-since, cooldowns, …
);
create index cells_next_poll_idx on public.cells (next_poll);

create table public.devices (
  token text primary key,                                            -- APNs device token or FCM registration token
  platform text not null check (platform in ('ios', 'android')),
  apns_env text check (apns_env in ('sandbox', 'production')),
  cell text not null references public.cells (id),
  lang text not null check (lang in ('ar', 'en')),
  types text[] not null default '{}',                                -- enabled weather events, e.g. {RAIN_START,THUNDER}
  quiet_preset smallint not null default 1 check (quiet_preset between 0 and 2),
  tz text not null,
  updated_at timestamptz not null default now(),
  constraint devices_apns_env_matches_platform check ((platform = 'ios') = (apns_env is not null))
);
create index devices_cell_idx on public.devices (cell);
create index devices_updated_at_idx on public.devices (updated_at);

-- Weather events detected per cell. Kept for tuning thresholds and for the
-- morning digest of events that happened during quiet hours.
create table public.events (
  id bigint generated always as identity primary key,
  cell text not null references public.cells (id) on delete cascade,
  type text not null,                                                -- RAIN_START, THUNDER, …
  at timestamptz not null default now(),
  digest boolean not null default false,                             -- held back for the morning digest
  sent_at timestamptz,
  observation jsonb                                                  -- what triggered it (provider, values)
);
create index events_cell_at_idx on public.events (cell, at desc);

-- "N people in Amman said the rain du'a today". Keys look like
-- "<momentId>:<cell>:<yyyy-mm-dd>"; said_marks de-duplicates per install
-- using a one-way hash, so the counter cannot be inflated by one phone.
create table public.counters (
  key text primary key,
  n bigint not null default 0
);

create table public.said_marks (
  hash text primary key,                                             -- sha256(installId:momentId:day)
  day date not null
);
create index said_marks_day_idx on public.said_marks (day);

-- City names for counters and push text ("around Amman"), from GeoNames.
create table public.cities (
  id bigint primary key,                                             -- GeoNames id
  ar text not null,
  en text not null,
  lat double precision not null,
  lon double precision not null,
  cell text not null
);
create index cities_cell_idx on public.cities (cell);

create table public.sky_cache (
  cell text primary key,
  computed_at timestamptz not null default now(),
  data jsonb not null
);

-- Official announcements that override the Umm al-Qura calculation, e.g. the
-- start of Ramadan in a given country.
create table public.calendar_overrides (
  id bigint generated always as identity primary key,
  region text not null,                                              -- ISO 3166 country code, or 'global'
  hijri_year int not null,
  hijri_month int not null check (hijri_month between 1 and 12),
  starts_on date not null,                                           -- Gregorian date of the 1st, as announced
  note text,
  created_at timestamptz not null default now(),
  unique (region, hijri_year, hijri_month)
);

-- "It is not raining here" and similar reports, used to tune thresholds.
create table public.feedback (
  id bigint generated always as identity primary key,
  cell text not null,
  event_id bigint references public.events (id) on delete set null,
  kind text not null check (kind in ('not_raining', 'wrong_time', 'other')),
  at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Lock everything down.
-- ---------------------------------------------------------------------------
alter table public.cells enable row level security;
alter table public.devices enable row level security;
alter table public.events enable row level security;
alter table public.counters enable row level security;
alter table public.said_marks enable row level security;
alter table public.cities enable row level security;
alter table public.sky_cache enable row level security;
alter table public.calendar_overrides enable row level security;
alter table public.feedback enable row level security;

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;

-- Atomic counter bump used by the api function.
create function public.bump_counter(p_key text)
returns bigint
language sql
security invoker
set search_path = ''
as $$
  insert into public.counters (key, n) values (p_key, 1)
  on conflict (key) do update set n = public.counters.n + 1
  returning n;
$$;

revoke execute on function public.bump_counter(text) from public, anon, authenticated;
