-- =============================================================================
-- Jerry's Notebook — Supabase schema (v1)
-- =============================================================================
-- Run this ONCE in the Supabase SQL editor (Dashboard → SQL Editor → New query
-- → paste → Run). It is safe to re-run: it uses "if not exists" and only seeds
-- rows that aren't already there.
--
-- Design goals:
--   * One source of truth. Claude reads/writes these tables in place (via the
--     Supabase MCP connector) so there are no duplicate files and no drift.
--   * You read/write the same tables from notebook.html on any device.
--   * Private by default: Row-Level Security blocks anonymous access. Only a
--     logged-in user (you, via magic link) or the service role (the MCP
--     connector) can see or change anything.
--
-- See NOTEBOOK.md for how each table is meant to be used.
-- =============================================================================

-- Needed for gen_random_uuid()
create extension if not exists "pgcrypto";

-- Small helper: bump updated_at on every UPDATE ----------------------------------
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =============================================================================
-- people  — one row per person you keep a file on
-- =============================================================================
create table if not exists people (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null,          -- short handle, e.g. 'brian'
  name          text not null,
  role          text,                           -- 'Runner', 'Partner', etc.
  relationship  text,                           -- 'Direct report / mentee'
  org           text,                           -- 'Dexter Builders'
  context       text,                           -- freeform background
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

drop trigger if exists people_updated_at on people;
create trigger people_updated_at before update on people
  for each row execute function set_updated_at();

-- =============================================================================
-- person_notes  — timestamped notes tied to a person
-- A person's "file" = all their notes ordered by note_date.
-- =============================================================================
create table if not exists person_notes (
  id          uuid primary key default gen_random_uuid(),
  person_id   uuid not null references people(id) on delete cascade,
  note_date   date not null default current_date,
  type        text not null default 'note',     -- '1:1' | 'expectation' | 'goal' | 'observation' | 'note'
  body        text not null,
  created_at  timestamptz not null default now()
);
create index if not exists person_notes_person_idx on person_notes(person_id, note_date desc);

-- =============================================================================
-- meetings  — recurring meeting definitions
-- =============================================================================
create table if not exists meetings (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null,           -- 'leadership', 'field-crew-am'
  name          text not null,
  cadence       text,                            -- 'Twice weekly', 'Biweekly'
  day_of_week   text,                            -- 'Thursday' (or comma list)
  participants  text,                            -- freeform
  notes         text,                            -- standing context / purpose
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

drop trigger if exists meetings_updated_at on meetings;
create trigger meetings_updated_at before update on meetings
  for each row execute function set_updated_at();

-- =============================================================================
-- meeting_entries  — one row per occurrence of a meeting
-- agenda = pre-meeting topics/prep, digest = post-meeting recap
-- =============================================================================
create table if not exists meeting_entries (
  id          uuid primary key default gen_random_uuid(),
  meeting_id  uuid not null references meetings(id) on delete cascade,
  entry_date  date not null,
  status      text not null default 'upcoming', -- 'upcoming' | 'done'
  agenda      text,                              -- pre-meeting notes / topics
  digest      text,                              -- post-meeting summary / decisions
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (meeting_id, entry_date)
);
create index if not exists meeting_entries_date_idx on meeting_entries(entry_date);

drop trigger if exists meeting_entries_updated_at on meeting_entries;
create trigger meeting_entries_updated_at before update on meeting_entries
  for each row execute function set_updated_at();

-- =============================================================================
-- calendar_items  — PERSONAL calendar (separate from the work Google calendar)
-- One-off items use item_date. Recurring items use recur (see NOTEBOOK.md).
-- =============================================================================
create table if not exists calendar_items (
  id                 uuid primary key default gen_random_uuid(),
  title              text not null,
  category           text,                       -- 'birthday'|'kids'|'family'|'appointment'|'reminder'
  who                text,                        -- 'daughter', 'family', a kid's name
  item_date          date,                        -- for one-off items
  recur              text,                         -- e.g. 'weekly:wed', 'yearly', 'yearly:03-14'
  reminder_lead_days int not null default 0,       -- how many days ahead to surface it
  notes              text,
  active             boolean not null default true,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index if not exists calendar_items_date_idx on calendar_items(item_date);

drop trigger if exists calendar_items_updated_at on calendar_items;
create trigger calendar_items_updated_at before update on calendar_items
  for each row execute function set_updated_at();

-- =============================================================================
-- Row-Level Security — private by default
-- =============================================================================
-- Enable RLS on every table, then allow full access ONLY to:
--   * authenticated  = you, signed in on notebook.html via magic link
--   * service_role   = the Supabase MCP connector Claude uses (bypasses RLS
--                      anyway, but listed for clarity)
-- The anon role gets NO policy, so anonymous visitors see nothing.

do $$
declare t text;
begin
  foreach t in array array['people','person_notes','meetings','meeting_entries','calendar_items']
  loop
    execute format('alter table %I enable row level security;', t);
    execute format('drop policy if exists "authenticated full access" on %I;', t);
    execute format(
      'create policy "authenticated full access" on %I for all to authenticated using (true) with check (true);',
      t);
  end loop;
end $$;

-- =============================================================================
-- SEED DATA — the first real rows so the notebook isn't empty on day one.
-- Guarded by "on conflict do nothing", so re-running won't duplicate.
-- =============================================================================

-- People ----------------------------------------------------------------------
insert into people (slug, name, role, relationship, org, context) values
  ('brian', 'Brian Muckstadt', 'Runner', 'Direct report / mentee', 'Dexter Builders',
   'Worked for Dexter Builders as a Runner previously, left, and came back. Did not '
   || 'finish college. After leaving, took a job with a friend''s family remodeling '
   || 'business, but they could not bring him on full-time, so he reapplied and '
   || 'returned. Currently a Runner but wants more responsibility long-term. Smart; '
   || 'Jerry is interested in mentoring him more.')
on conflict (slug) do nothing;

-- Brian's notes from the 2026-07-16 1:1 --------------------------------------
insert into person_notes (person_id, note_date, type, body)
select p.id, v.note_date, v.type, v.body
from people p
join (values
  (date '2026-07-16', '1:1',
   'Talked through two long-term paths for Brian: Project Management vs. Carpenter. '
   || 'Walked through a list of skills each path would be served by. Goal was to give '
   || 'him a clear picture of what growth looks like in either direction.'),
  (date '2026-07-16', 'goal',
   'Wants more responsibility long-term — growth beyond the Runner role.'),
  (date '2026-07-16', 'observation',
   'Smart and motivated. Worth investing mentoring time in.'),
  (date '2026-07-16', 'note',
   'TODO: capture the actual skills lists for each path (PM vs. Carpenter) so we can '
   || 'turn them into a concrete development plan and revisit next 1:1.')
) as v(note_date, type, body) on p.slug = 'brian'
where not exists (
  select 1 from person_notes pn
  where pn.person_id = p.id and pn.note_date = date '2026-07-16'
);

-- Meetings --------------------------------------------------------------------
insert into meetings (slug, name, cadence, day_of_week, participants, notes) values
  ('leadership', 'Leadership Meeting', 'Twice weekly', NULL, 'Partners',
   'Recurring leadership meeting held twice a week with the partners. Holds pre-meeting '
   || 'topics/agenda and post-meeting digests in meeting_entries.'),
  ('field-crew-am', 'Field Crew Morning Meeting', 'Biweekly', 'Thursday', 'Field crew',
   'Biweekly morning meeting with the field crew, Thursdays. Holds pre-meeting '
   || 'topics/agenda and post-meeting digests in meeting_entries.')
on conflict (slug) do nothing;

-- Personal calendar — example recurring item mentioned in planning ------------
insert into calendar_items (title, category, who, recur, reminder_lead_days, notes)
select 'Swim', 'kids', 'daughter', 'weekly:wed', 1,
       'Daughter''s weekly swim (Wednesdays). Example recurring personal reminder — '
       || 'adjust time/details as needed.'
where not exists (
  select 1 from calendar_items where title = 'Swim' and who = 'daughter'
);

-- =============================================================================
-- Done. Verify with:  select * from people; select * from person_notes;
-- =============================================================================
