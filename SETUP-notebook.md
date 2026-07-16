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
3. You should see "Success." Check the **Table Editor** — you'll see the five
   tables (`people`, `person_notes`, `meetings`, `meeting_entries`,
   `calendar_items`), ready for data.

## 3. Grab your keys

Left sidebar → **Project Settings** (gear) → **API**. Copy these two — you'll
need them below:

| Key | Where it's used | Secret? |
|-----|-----------------|---------|
| **Project URL** (`https://xxxx.supabase.co`) | `notebook.html` | no |
| **anon / publishable** key | `notebook.html` | no (safe to ship — RLS protects data) |

> The `anon`/publishable key is *designed* to be public. It can't read anything
> because Row-Level Security blocks anonymous access — only a logged-in user can.
>
> You do **not** need the `service_role`/secret key here. Claude's connector
> (step 6) authenticates by **OAuth**, not by a pasted key — so the secret key
> never has to leave Supabase.

## 4. Turn on magic-link login (so the web page is really private)

1. Left sidebar → **Authentication** → **Sign In / Providers** → make sure
   **Email** is enabled. Turn **Confirm email** on.
2. **Authentication → URL Configuration** → set **Site URL** to
   `https://jertyr.github.io/jt-website/notebook.html` and add the same under
   **Redirect URLs** (or `https://jertyr.github.io/jt-website/**` to cover the
   whole site). Note the `/jt-website/` path — this repo is a GitHub Pages
   *project* site, so it's served under that subpath, not the domain root. If
   the URLs here don't match the page's real address, the magic link bounces.
3. **Authentication → Users → Add user** → add yourself (`geraldatyrrell@gmail.com`).
   This is the only account that will be allowed in.

## 5. Wire up the web page

Open `notebook.html` and fill in the two constants near the top of the script:

```js
const SUPABASE_URL  = "https://xxxx.supabase.co";   // your Project URL
const SUPABASE_ANON = "eyJ...";                      // your anon/public key
```

Commit that (or just send both values to Claude and it'll do it). Then visit
`https://jertyr.github.io/jt-website/notebook.html`, enter your email, click the
magic link Supabase emails you, and you're in. It works the same on your phone.

## 6. Connect Claude to the notebook (the MCP connector)

This is what lets Claude read/write the notebook in place. It uses **OAuth** —
no keys to copy.

1. In **claude.ai** → **Settings → Connectors** (on web, the connectors/plug
   icon near the chat box → **Browse connectors**).
2. Find **Supabase** ("Manage databases, authentication, and storage") →
   **Connect**.
3. It sends you through **Supabase OAuth** — log in and **authorize**, picking
   the organization/project that holds this notebook. Leave any **read-only**
   toggle **off** so Claude can write.
4. **Enable the connector for this chat** (the same connectors icon by the chat
   box — switch Supabase on for the conversation).
5. Ask Claude to read your notebook — it should return your rows. From then on
   it can add 1:1 notes, meeting agendas/digests, calendar items, and tasks
   directly.

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
