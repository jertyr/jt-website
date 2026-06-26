# Checklist cloud sync (Flavor B) — setup

This turns the checklist page from "edits live in one browser, sync by copy-paste"
into "type anywhere, it auto-saves to the repo." No more PRs for list changes.

**How it works:** the page reads `checklist.json` directly (public). For *writes*,
it sends the data to a small Cloudflare Worker that holds a secret GitHub token and
commits the file for you. The write password is checked on the Worker (server-side),
so it's real protection.

You only do this once. Until `WORKER_URL` is filled in (last step), the page keeps
working exactly as it does today (copy-paste sync), so nothing breaks in the meantime.

---

## 1. Create a GitHub token (so the Worker can save the file)

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**
   (https://github.com/settings/personal-access-tokens/new).
2. **Token name:** `checklist-sync`. **Expiration:** your choice (e.g. 1 year).
3. **Resource owner:** your account (`jertyr`).
4. **Repository access → Only select repositories →** pick `jertyr/jt-website`.
5. **Permissions → Repository permissions → Contents →** set to **Read and write**.
6. Click **Generate token** and **copy it** (you won't see it again).

## 2. Create the Cloudflare Worker

1. Make a free account at https://dash.cloudflare.com and verify your email.
2. Left sidebar → **Workers & Pages** → **Create** → **Create Worker**.
3. Name it `checklist-sync` → **Deploy** (it deploys a placeholder).
4. Click **Edit code**. Delete the placeholder and paste the entire contents of
   [`worker.js`](./worker.js) from this repo. Click **Deploy**.

## 3. Add the settings the Worker needs

In the Worker → **Settings** → **Variables and Secrets**:

**Add these as Secrets (encrypt):**
| Name | Value |
|------|-------|
| `GITHUB_TOKEN` | the token from step 1 |
| `CHECKLIST_PASSWORD` | a password you choose (you'll type it into the page once) |

**Add these as plain Variables (Text):**
| Name | Value |
|------|-------|
| `REPO` | `jertyr/jt-website` |
| `BRANCH` | `master` |
| `FILE_PATH` | `checklist.json` |
| `ALLOW_ORIGIN` | `https://jertyr.github.io` |

Click **Deploy** again so the variables take effect.

## 4. Get the Worker URL

On the Worker's overview page, copy its URL — looks like
`https://checklist-sync.<your-subdomain>.workers.dev`.

## 5. Turn it on in the page

Open `checklist.html` and set the constant near the top of the script:

```js
const WORKER_URL = "https://checklist-sync.<your-subdomain>.workers.dev";
```

Commit that one-line change (or just send the URL to Claude and it'll do it).
Once it's live, the page header shows a **"✓ saved to cloud"** indicator after each edit.

---

## Using it

- The **first time** you make a change on a device, the page asks for the
  `CHECKLIST_PASSWORD` once, then remembers it on that device.
- Every add / check-off / edit auto-saves to `checklist.json` (debounced ~1s).
- Other devices see changes after you tap **Reload from repo** (GitHub Pages takes
  1–2 min to publish). Claude still reads/edits the same file directly.
- If a save fails (offline, wrong password), the indicator turns red — click it to retry.
  Your data is still safe in the browser either way.

## Notes / security

- The write password is stored as a Cloudflare secret and checked server-side, so
  it actually protects writes. The page's `admin`/`pass` login is still only cosmetic
  (it just hides the list from casual viewers).
- The Worker free tier (100k requests/day) is far more than this needs.
- Each save is a commit to `master`. That's expected — it's how the live file updates.
