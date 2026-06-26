/**
 * Cloudflare Worker — checklist cloud sync (Flavor B)
 *
 * Receives the checklist from the web page and commits it to checklist.json
 * in the GitHub repo. The page reads checklist.json directly (public), so
 * this Worker only handles WRITES. The shared password is checked here on
 * the server, so it is real protection (unlike the page's cosmetic login).
 *
 * Configure these in the Cloudflare dashboard (Worker → Settings → Variables):
 *   Secrets (encrypted):
 *     GITHUB_TOKEN        fine-grained PAT with Contents: Read & Write on the repo
 *     CHECKLIST_PASSWORD  the password you'll type into the page once
 *   Plain variables:
 *     REPO                "jertyr/jt-website"
 *     BRANCH              "master"
 *     FILE_PATH           "checklist.json"
 *     ALLOW_ORIGIN        "https://jertyr.github.io"   (or "*" to allow any)
 *
 * See SETUP-checklist-sync.md for click-by-click instructions.
 */
export default {
  async fetch(request, env) {
    const cors = {
      "Access-Control-Allow-Origin": env.ALLOW_ORIGIN || "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });
    if (request.method !== "POST") return json({ error: "method not allowed" }, 405, cors);

    let body;
    try { body = await request.json(); }
    catch { return json({ error: "invalid json" }, 400, cors); }

    if (!body.token || body.token !== env.CHECKLIST_PASSWORD)
      return json({ error: "unauthorized" }, 401, cors);
    if (!body.data || !Array.isArray(body.data.items))
      return json({ error: "bad data" }, 400, cors);

    const repo   = env.REPO;
    const path   = env.FILE_PATH || "checklist.json";
    const branch = env.BRANCH || "master";
    const api    = `https://api.github.com/repos/${repo}/contents/${encodeURIComponent(path)}`;
    const gh = {
      "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
      "Accept": "application/vnd.github+json",
      "User-Agent": "checklist-sync-worker",
      "Content-Type": "application/json",
    };

    // Look up the current file SHA (required to update an existing file).
    let sha;
    const getRes = await fetch(`${api}?ref=${branch}`, { headers: gh });
    if (getRes.ok) sha = (await getRes.json()).sha;
    else if (getRes.status !== 404)
      return json({ error: "github read failed", status: getRes.status }, 502, cors);

    const text = JSON.stringify(body.data, null, 2) + "\n";
    const content = base64(text);

    const putRes = await fetch(api, {
      method: "PUT",
      headers: gh,
      body: JSON.stringify({
        message: "Update checklist via web app",
        content,
        branch,
        ...(sha ? { sha } : {}),
      }),
    });
    if (!putRes.ok) {
      const detail = await putRes.text();
      return json({ error: "github write failed", status: putRes.status, detail }, 502, cors);
    }
    return json({ ok: true }, 200, cors);
  },
};

function json(obj, status, cors) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });
}

// UTF-8 safe base64 encode (handles accents/emoji in titles).
function base64(str) {
  const bytes = new TextEncoder().encode(str);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}
