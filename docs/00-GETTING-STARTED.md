# 0. Getting Started — a friendly, step-by-step walkthrough

> New to Docker or PostgreSQL? Start here. This guide takes you from a fresh
> machine to a working database with all extensions, then shows the optional
> extras — in plain language, one step at a time. Every step says **what success
> looks like** so you always know you're on track.

If a step misbehaves, jump to [doc 9 — Troubleshooting](09-TROUBLESHOOTING.md).

---

## What is this, in one paragraph?

This repository runs **PostgreSQL 17 inside Docker**, pre-loaded with many useful
**extensions** (Foreign Data Wrappers to query MySQL/SQL Server/other Postgres,
`pgvector` for AI embeddings, `pg_cron` for scheduling, and more). It's tuned so
it stays light on a laptop that's also running other heavy apps. You run a couple
of commands, and you get a ready-to-use database — no manual installs.

**Mental model:**

```
   your app (NestJS, etc.)                    your laptop
   ───────────────────────                    ───────────
            │  connects to port 15409
            ▼
   ┌───────────────────────────┐   Docker container (capped: 1.5 GB / 2 CPU)
   │  PostgreSQL 17 + extensions│   ── data saved in a Docker "volume"
   └───────────────────────────┘
            │  (optional) Foreign Data Wrappers
            ▼
   other databases (MySQL / SQL Server / Postgres)
```

---

## Step 1 — Check the requirements

You need **Docker** and **Docker Compose v2**. Check:

```bash
docker --version            # expect Docker 24+ (this laptop: 29.x)
docker compose version      # expect v2+ (this laptop: v5.x)
```

✅ **Success:** both print a version number.
📖 Details & laptop budget: [doc 1 — Requirements](01-REQUIREMENTS.md).

---

## Step 2 — Let Docker run without `sudo` (one-time)

On this laptop the user isn't in the `docker` group yet, so commands would fail
with `permission denied`. Fix it once:

```bash
sudo usermod -aG docker $USER
# then LOG OUT and back in (or run: newgrp docker)
docker run --rm hello-world          # verify
```

✅ **Success:** `hello-world` prints "Hello from Docker!" **without** `sudo`.

> Prefer not to? Then prefix every `docker`/`make` command with `sudo`.

---

## Step 3 — Get the code

```bash
git clone https://github.com/programmerShinobi/postgresql-fdw.git
cd postgresql-fdw
```

✅ **Success:** you're inside the `postgresql-fdw` folder (`ls` shows
`docker-compose.yml`, `Makefile`, `docs/`, …).

---

## Step 4 — Configure your secrets (`.env`)

The project never ships real passwords. You create your own local `.env`:

```bash
make init          # copies .env.example -> .env AND installs the safety hook
```

Now open `.env` and set a **strong password**. Generate one:

```bash
openssl rand -base64 36 | tr -d '/+=' | cut -c1-48
```

Paste it as `POSTGRES_PASSWORD=...` in `.env`.

✅ **Success:** `.env` exists and `POSTGRES_PASSWORD` is no longer `CHANGE_ME...`.
🔒 `.env` is git-ignored — it will never be committed. See [doc 10 — Security](10-SECURITY.md).

> **Don't change `POSTGRES_DB`** unless you read the note in `.env` (it's linked to
> two settings in `postgresql.conf`). For your first run, leave the defaults.

---

## Step 5 — Build the image

```bash
make build
```

This downloads PostgreSQL 17 and compiles/installs every extension.

✅ **Success:** it ends without errors.
⏳ The **first** build takes a few minutes (it compiles `mysql_fdw`). Later builds
are cached and fast. Grab a coffee. ☕

---

## Step 6 — Start the database

```bash
make up
```

This starts **only** PostgreSQL (optional services stay off — see Step 11).

✅ **Success:**
```bash
make ps        # STATUS shows "healthy"
make health    # prints "... accepting connections"
```

---

## Step 7 — Confirm the extensions are there

```bash
make extensions
```

✅ **Success:** a table of ~20 extensions: `postgres_fdw`, `mysql_fdw`, `tds_fdw`,
`file_fdw`, `vector`, `pg_cron`, `pg_partman`, `pgaudit`, … plus the basics.
📖 What each one does: [doc 4 — Extensions](04-EXTENSIONS.md).

---

## Step 8 — Connect and try it

Open a database shell:

```bash
make psql
```

Try a query:

```sql
SELECT version();
SELECT gen_random_uuid();      -- from pgcrypto
\dx                            -- list installed extensions
\q                             -- quit
```

From your application, use this connection string (with your password):

```
postgresql://local_dev:<password>@127.0.0.1:15409/local_db
```

✅ **Success:** queries return results.
📖 Wiring into NestJS/TypeORM/Prisma: [doc 6 — NestJS Integration](06-NESTJS-INTEGRATION.md).

---

## Step 9 — Day-to-day commands

```bash
make up          # start core Postgres
make down        # stop everything (your data is kept)
make psql        # open a SQL shell
make logs        # watch what the database is doing
make stats       # live CPU/RAM the container is using
make backup      # save a snapshot into ./backups
make help        # see all commands
```

> `make down` keeps your data. Only `make destroy` deletes it (it removes the
> volume) — use that to start completely fresh.

✅ **Success:** you can stop/start without losing data.

---

## Step 10 — Make a backup (recommended early)

```bash
make backup
```

✅ **Success:** a file appears in `./backups/` (e.g. `local_db_2026….dump.gz`).
📖 Restoring & scheduled backups: [doc 7 — Backup & Restore](07-BACKUP-RESTORE.md).

---

## Step 11 — Turn on optional features (only if you need them)

A plain `make up` is intentionally minimal. Extras are **opt-in** and capped, so
they never slow your laptop:

```bash
make up-pooler    # PgBouncer connection pooler (port 6432) — for many app connections
make up-backup    # automatic scheduled backups
make up-ui        # Adminer web UI at http://localhost:8080 — a browser GUI
make up-metrics   # Prometheus metrics at http://localhost:9187/metrics
make up-all       # everything at once
```

Turn them all off again with `make down`, then `make up` for core only.

✅ **Success:** e.g. after `make up-ui`, opening http://localhost:8080 shows a
login page (System: PostgreSQL, Server: `postgres`, your user/DB from `.env`).
📖 Full matrix & tuning: [doc 12 — Optional Features](12-OPTIONAL-FEATURES.md).

---

## Step 12 — (Advanced) Import data from another PostgreSQL

If you have an existing database to copy in:

```bash
cp .env.source.example .env.source   # fill in the source connection (gitignored)
./scripts/migration/check-compatibility.sh   # checks it'll import cleanly
make up
./scripts/migration/import-from-source.sh
```

✅ **Success:** the compatibility report ends with "Safe to import", and after the
import your tables appear in `make psql` (`\dt`).
📖 Full guide & caveats: [doc 11 — Import from Source](11-IMPORT-FROM-SOURCE.md).

---

## You're done 🎉

You now have a tuned, extension-rich PostgreSQL for development. Recommended next
reads, in order:

1. [Resource Tuning](05-RESOURCE-TUNING.md) — why it's laptop-safe & how to rebalance
2. [Security](10-SECURITY.md) — keep credentials safe (important!)
3. [Optional Features](12-OPTIONAL-FEATURES.md) — pooler, backups, UI, metrics

### Quick "is everything OK?" checklist

- [ ] `make ps` → healthy
- [ ] `make extensions` → ~20 rows
- [ ] `make psql` → `SELECT 1;` works
- [ ] `make backup` → a file in `./backups/`
- [ ] You set a strong `POSTGRES_PASSWORD` and never committed `.env`

---

⬅️ Back to the [README](../README.md) · Next: [1. Requirements »](01-REQUIREMENTS.md)
