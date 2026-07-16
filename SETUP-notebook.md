# Notebook setup — Supabase (one-time)

You don't have a Supabase account yet, so this walks you through it from zero.
Everything Claude built (`supabase/schema.sql`, `NOTEBOOK.md`, `notebook.html`)
just sits ready until you finish these steps. Nothing here touches your live site
until the very last step.

Total time: ~15 minutes. Free tier is plenty for this.

---

## 1. Create the Supabase project

1. Go to **https://supabase.com** → **Start your project** → sign in with GitHub
   (`jertyr`) or email.
2. **New project.** Name it `notebook`. Choose a **region** near you (e.g.
   *East US*). Set a **database password** and save it in your password manager.
3. Click **Create new project** and wait ~2 minutes for it to provision.

## 2. Create the tables (run the schema)

1. In the project, left sidebar → **SQL Editor** → **New query**.
2. Open [`supabase/schema.sql`](./supabase/schema.sql) from this repo, copy the
   **entire** file, paste it in, and click **Run**.
3. You should see "Success." Check the **Table Editor** — you'll see `people`,
   `person_notes`, `meetings`, `meeting_entries`, `calendar_items`, already
   seeded with Brian and your two meetings.

## 3. Grab your keys

Left sidebar → **Project Settings** (gear) → **API**. Copy these two — you'll
need them below:

| Key | Where it's used | Secret? |
|-----|-----------------|---------|
| **Project URL** (`https://xxxx.supabase.co`) | `notebook.html` and MCP | no |
| **anon / public** key | `notebook.html` | no (safe to ship — RLS protects data) |
| **service_role** key | the Supabase MCP connector only | **YES — never put in the website** |

> The `anon` key is *designed* to be public. It can't read anything because
> Row-Level Security blocks anonymous access — only a logged-in user can. The
> `service_role` key bypasses RLS, so it stays secret and lives only in the MCP
> connector config, never in the repo or the web page.

## 4. Turn on magic-link login (so the web page is really private)

1. Left sidebar → **Authentication** → **Sign In / Providers** → make sure
   **Email** is enabled. Turn **Confirm email** on.
2. **Authentication → URL Configuration** → add your site URL under **Redirect
   URLs**: `https://jertyr.github.io/notebook.html` (and `http://localhost`
   if you ever test locally).
3. **Authentication → Users → Add user** → add yourself (`geraldatyrrell@gmail.com`).
   This is the only account that will be allowed in.

## 5. Wire up the web page

Open `notebook.html` and fill in the two constants near the top of the script:

```js
const SUPABASE_URL  = "https://xxxx.supabase.co";   // your Project URL
const SUPABASE_ANON = "eyJ...";                      // your anon/public key
```

Commit that (or just send both values to Claude and it'll do it). Then visit
`https://jertyr.github.io/notebook.html`, enter your email, click the magic link
Supabase emails you, and you're in. It works the same on your phone.

## 6. Connect Claude to the notebook (the MCP connector)

This is what lets Claude read/write the notebook in place.

1. In Supabase: **Project Settings → Access Tokens** (or reuse the
   `service_role` key from step 3).
2. In the **Claude app** (desktop or mobile) → **Settings → Connectors →
   Add connector → Supabase** (the official Supabase MCP connector). Paste your
   **Project URL** and **service_role** access token when prompted.
3. Once connected, ask Claude: *"read Brian's notebook file"* — it should return
   the seeded notes. From then on it can add 1:1 notes, meeting agendas/digests,
   and calendar items directly.

> If you don't see a built-in Supabase connector, the official server is
> published at **`@supabase/mcp-server-supabase`** — Claude can walk you through
> adding it as a custom MCP server with the same URL + service_role token.

---

## What's next
- **Phase 2 — daily digest:** a Supabase Edge Function on a morning cron that
  emails you a 3–5 day lookahead, merging your personal `calendar_items` with
  your **real work Google calendar** (read-only, so no second copy). Tell Claude
  when you're ready and it'll build the function.
- **Phase 3 — checklist on the same backend:** migrate `checklist.json` into a
  Supabase `tasks` table so the checklist and notebook share one database.

## Security recap
- Data is private via Row-Level Security; the public `anon` key can't read it.
- The `service_role` key lives only in the MCP connector — never in the repo.
- Only accounts you add under **Authentication → Users** can sign into the page.
