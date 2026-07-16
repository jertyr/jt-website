# Jerry's Notebook — how it works

A personal notebook backed by **Supabase** (hosted Postgres). One source of
truth: Claude reads/writes the tables **in place** via the Supabase MCP
connector, and Jerry reads/writes the same tables from `notebook.html` on any
device. No duplicate files, no drift.

This file is the **contract** — the conventions Claude follows so the data stays
consistent over time. If you (Claude) are reading this, follow it exactly.

- **Schema / setup:** `supabase/schema.sql`
- **First-time setup steps:** `SETUP-notebook.md`

---

## Tables at a glance

| Table | One row = | Use it for |
|---|---|---|
| `people` | a person Jerry keeps a file on | identity/background: role, relationship, org, context |
| `person_notes` | one dated note about a person | 1:1 notes, expectations, goals, observations |
| `meetings` | a recurring meeting definition | Leadership (2×/wk), Field Crew AM (biweekly Thu) |
| `meeting_entries` | one occurrence of a meeting | pre-meeting agenda + post-meeting digest, per date |
| `calendar_items` | a personal calendar entry | birthdays, kids' activities, appointments, reminders |

Everything is private (Row-Level Security). Anonymous users see nothing.

---

## Conventions (read before writing)

### `people`
- `slug` is the stable handle — lowercase, no spaces (e.g. `brian`). Use it to
  look people up; never change it once set.
- Put durable background in `context` (who they are, history). Put anything
  **dated** in `person_notes`, not here.
- Set `active = false` instead of deleting when someone leaves.

### `person_notes`
- **"Brian's file"** = `select * from person_notes where person_id = (select id
  from people where slug='brian') order by note_date desc`.
- `type` is one of: `1:1`, `expectation`, `goal`, `observation`, `note`.
  Use `1:1` for the summary of a one-on-one; break out explicit expectations and
  goals as their own rows so they're easy to revisit.
- One note per idea — small rows are easier to review than one giant blob.
- `note_date` = the day it happened (default today).

### `meetings` + `meeting_entries`
- `meetings` holds the *definition* (name, cadence, participants). Rarely changes.
- `meeting_entries` holds each occurrence. Before a meeting, create/append the
  `agenda` (topics to raise). After, fill `digest` (what was decided / follow-ups)
  and set `status = 'done'`.
- One entry per (meeting, date) — enforced by a unique constraint. To add a topic
  to an upcoming meeting, update that entry's `agenda`, don't make a second row.
- Look up a meeting by `slug`: `leadership`, `field-crew-am`.

### `calendar_items` (PERSONAL only)
- This is **separate from Jerry's work Google calendar** — he won't maintain a
  second copy of work. Only personal life goes here: birthdays, kids' activities,
  family commitments, appointments, recurring reminders.
- One-off item → set `item_date`, leave `recur` empty.
- Recurring item → leave `item_date` empty, set `recur`:
  - `weekly:mon` … `weekly:sun` — every week on that day (e.g. `weekly:wed`)
  - `yearly:MM-DD` — every year on that date (e.g. `yearly:03-14` for a birthday)
  - `yearly` — annually on `item_date`'s month/day
  - `monthly:DD` — every month on that day-of-month
- `reminder_lead_days` = how many days ahead the digest should surface it.
- `category`: `birthday` | `kids` | `family` | `appointment` | `reminder`.

---

## Daily digest (phase 2 — planned, not built yet)

A 3–5 day lookahead delivered by **email each morning** (Gmail). It will merge:
1. `calendar_items` due in the window (expanding `recur` rules), plus
2. upcoming `meeting_entries`, plus any open follow-ups in `person_notes`, plus
3. Jerry's **real work Google calendar, read live/read-only** — so he never keeps
   a second copy of work events.

Delivery mechanism: a Supabase **Edge Function** on a cron schedule. Until that's
built, Claude can generate the same lookahead on request from these tables + the
Google Calendar connector.

## Later (phase 3)
Fold the existing checklist (`checklist.json` + Cloudflare Worker) into a
Supabase `tasks` table so it shares this backend — the "same backend for a future
checklist app" goal from the original plan.

---

## Access model (why it's safe)
- **Claude** connects with the Supabase **service role** through the MCP
  connector → full read/write, bypasses RLS.
- **Jerry** signs into `notebook.html` with a **magic link** (Supabase Auth) →
  the `authenticated` role, full read/write via RLS policy.
- **Everyone else** (anon) → no policy → sees nothing. The page is on public
  GitHub Pages, but the data is not public.
