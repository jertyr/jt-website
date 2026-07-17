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
--     logged-in user (you, via magic link) or the Supabase MCP connector Claude
--     uses (OAuth to your Supabase account) can see or change anything.
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
  slug          text unique not null,          -- short handle, e.g. 'jdoe'
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
-- tasks  — checklist / to-do items (migrated from the old checklist.json)
-- Shares this backend so the checklist and notebook are one database.
-- =============================================================================
create table if not exists tasks (
  id          uuid primary key default gen_random_uuid(),
  legacy_id   int unique,                       -- original checklist.json id (for the one-time migration)
  title       text not null,
  job         text,                              -- grouping: 'Personal', a client/job name, etc.
  done        boolean not null default false,
  due         date,
  created     date,                              -- when the task was first noted
  completed   date,                              -- when it was checked off
  recur       text,                              -- e.g. 'biweekly' (freeform, as in the old app)
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists tasks_done_due_idx on tasks(done, due);

drop trigger if exists tasks_updated_at on tasks;
create trigger tasks_updated_at before update on tasks
  for each row execute function set_updated_at();

-- =============================================================================
-- projects  — one row per ongoing project you keep a running log on
-- Rarely changes; click into one to read/add its notes.
-- =============================================================================
create table if not exists projects (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,             -- stable handle, e.g. 'home-care'
  name        text not null,
  status      text,                              -- freeform, e.g. 'active', 'on hold'
  context     text,                              -- durable description / background
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists projects_updated_at on projects;
create trigger projects_updated_at before update on projects
  for each row execute function set_updated_at();

-- =============================================================================
-- project_notes  — intentionally unstructured, timestamped log tied to a project
-- One project's log = all its notes ordered by note_date. Ask Claude to
-- summarize a project any time and it reads across these rows.
-- =============================================================================
create table if not exists project_notes (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  note_date   date not null default current_date,
  body        text not null,
  created_at  timestamptz not null default now()
);
create index if not exists project_notes_project_idx on project_notes(project_id, note_date desc);

-- =============================================================================
-- Row-Level Security — private by default
-- =============================================================================
-- Enable RLS on every table, then allow full access ONLY to:
--   * authenticated  = you, signed in via magic link (notebook.html)
--   * the Supabase MCP connector Claude uses (connects via OAuth to your
--     Supabase account, so it operates with elevated privileges)
-- The anon role gets NO policy, so anonymous visitors see nothing.

do $$
declare t text;
begin
  foreach t in array array['people','person_notes','meetings','meeting_entries','calendar_items','tasks','projects','project_notes']
  loop
    execute format('alter table %I enable row level security;', t);
    execute format('drop policy if exists "authenticated full access" on %I;', t);
    execute format(
      'create policy "authenticated full access" on %I for all to authenticated using (true) with check (true);',
      t);
  end loop;
end $$;

-- =============================================================================
-- Seed / personal data is intentionally NOT stored in this (public) repo.
-- Real rows (people, meetings, calendar items, notes) are loaded privately —
-- either written directly by Claude via the Supabase MCP connector, or by
-- pasting a locally generated import into the Supabase SQL editor. This file
-- defines STRUCTURE only; keep personal data out of git.
-- =============================================================================

-- =============================================================================
-- Done. Verify with:  select * from people;  select * from tasks;
-- =============================================================================
