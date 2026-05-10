# ReliefNet cloud stack — setup order (Claude + MongoDB + Vultr)

Use this **order** whenever you (re)deploy; when the **code changes**, redo the steps that apply (pull → `npm install` → restart API → `flutter pub get` / rebuild app).

---

## 1. Anthropic (Claude API)

1. Sign in at [Anthropic Console](https://console.anthropic.com/).
2. **API keys** → create a key → copy it (starts with `sk-ant-…`).
3. Optional: set **`CLAUDE_MODEL`** in `server/.env` to pin one model id. If unset, the API calls Anthropic’s **Models list** and picks a working Sonnet/Haiku-style id for your key (so hardcoded ids do not 404 as Anthropic renames snapshots).

**→ Put in `server/.env`:** `ANTHROPIC_API_KEY=...`  
**→ Never commit** `.env` or paste the key into the Flutter app.

---

## 2. MongoDB Atlas

1. [MongoDB Atlas](https://cloud.mongodb.com) → create a **free cluster** in a region **near your Vultr VPS**.
2. **Database Access** → database user (password) → save password (**URL-encode** special chars in the URI).
3. **Network Access** → allow the **Vultr server’s public IP** (the machine running Node), e.g. `144.202.115.202/32`, or temporarily `0.0.0.0/0` for demos (less secure).  
   **Important:** this is the **server** IP Atlas will see when Mongoose connects **from** Vultr — **not** your laptop IP (unless the API runs only on your Mac).
4. **Connect** → **Drivers** → copy **`mongodb+srv://…`** URI and add DB name, e.g. `…/reliefnet?retryWrites=true&w=majority`.

**→ Put in `server/.env`:** `MONGODB_URI=...`

---

## 3. Vultr (API host)

1. Create a **Cloud Compute** VM (e.g. Ubuntu 22.04/24.04) near Atlas.
2. Note **public IPv4** (example for this project: **`144.202.115.202`**).
3. **Firewall group** (attach it to this instance — **Linked instances** must not be 0):
   - **TCP 3000** → source `0.0.0.0/0` (API for phones / demo), or narrower IPs if you prefer.
   - **SSH 22** → source should be **your laptop’s public IP** `/32` (the machine you run `ssh` **from**), **not** the Vultr server’s own IP. If you lock yourself out, fix the rule from the Vultr web UI or use the web console. For a rough hackathon only, SSH from `0.0.0.0/0` is easier but less safe.
4. **On your Mac (Terminal)** — SSH into the server (website is only for steps 1–3):

```bash
ssh root@144.202.115.202
```

5. On the **remote shell** after login:

```bash
cd /path/to/ReliefNet/server   # wherever you cloned the repo
npm install
npm run init-env               # if .env missing; then: nano .env
# set PORT=3000, MONGODB_URI=..., ANTHROPIC_API_KEY=...
npm start
```

6. **Verify from your Mac** (new Terminal tab while `npm start` is running on the server):

```bash
curl http://144.202.115.202:3000/health
```

Expect: `"ok": true`, `"mongo": true`, `"anthropic": true`.

**When code updates:** `git pull` → `npm install` (if `package.json` changed) → restart the Node process.

**Replace `144.202.115.202`** everywhere if Vultr gives you a different public IP later.

---

## 4. Local / laptop `server/.env` (development)

Same variables as on Vultr:

```env
PORT=3000
MONGODB_URI=...
ANTHROPIC_API_KEY=...
# optional:
# CLAUDE_MODEL=claude-3-5-sonnet-20241022
```

Bootstrap file: `npm run init-env` (from `server/`) copies `.env.example` → `.env` if missing.

---

## 5. Flutter app → API URL

The app reads **`API_BASE_URL`** at compile time
(current default: `http://192.168.137.1:3000`).

- **Simulator on same Mac as API:** default is fine.
- **Physical iPhone → Vultr API** (example host):

```bash
flutter run -d <device_id> --dart-define=API_BASE_URL=http://144.202.115.202:3000
```

Or use **`./scripts/run_ios.sh`** and append defines:

```bash
./scripts/run_ios.sh <device_id> --dart-define=API_BASE_URL=http://144.202.115.202:3000
```

Offline hub URL is also configurable at compile time:

```bash
flutter run -d <device_id> --dart-define=HUB_BASE_URL=http://192.168.137.1:3001
```

**When code or API host changes:** rebuild / re-run with the correct `--dart-define`.

---

## Quick verify

| Step | Check |
|------|--------|
| Atlas | URI works from Vultr IP (Network Access). |
| Claude | `GET /health` shows `"anthropic": true`. |
| Mongo | `GET /health` shows `"mongo": true`. |
| App | Submit SOS → incident appears in dashboard with severity/category/summary. |

---

## Reference: env vars (server)

| Variable | Required | Purpose |
|----------|----------|---------|
| `MONGODB_URI` | yes | Atlas connection string |
| `ANTHROPIC_API_KEY` | yes | Claude API |
| `PORT` | no | Listen port (default 3000) |
| `CLAUDE_MODEL` | no | Override model id |
