# 2. Installation

> From zero to a running, healthy database with all extensions live.

## 2.0 Docker permissions (one-time, do this first)

On this laptop the `faqih` user is **not** in the `docker` group, so `docker`
and `make` will fail with `permission denied ... /var/run/docker.sock`. Fix once:

```bash
sudo usermod -aG docker $USER
# log out & back in (or run: newgrp docker), then verify:
docker run --rm hello-world
```

Skip only if you intend to prefix every command with `sudo`.

## 2.1 Get the code

```bash
git clone https://github.com/programmerShinobi/postgresql-fdw.git
cd postgresql-fdw
```

## 2.2 Create your `.env`

```bash
cp .env.example .env
```

- [ ] **Change `POSTGRES_PASSWORD`.** Generate a strong one:

```bash
openssl rand -base64 36 | tr -d '/+=' | cut -c1-48
```

Paste it into `.env`. Review the other values (port, memory caps) — defaults are
sane for the reference laptop. Full reference: [doc 3 — Configuration](03-CONFIGURATION.md).

> `make init` does the copy for you and reminds you to edit the password.

## 2.3 Build the image

```bash
make build          # or: docker compose build
```

> ⏳ **First build is slow** (a few minutes): it compiles `mysql_fdw` from
> source and installs the extension packages. Subsequent builds are cached.

## 2.4 Start the database

```bash
make up             # or: docker compose up -d
```

On the **first** start, Postgres initialises the data directory and runs the
scripts in `scripts/init/` — this is when every extension gets created.

## 2.5 Verify it's healthy

```bash
make health         # expects: "... accepting connections"
make ps             # STATUS should show "healthy"
make logs           # watch the boot; look for "database system is ready"
```

- [ ] `pg_isready` reports **accepting connections**
- [ ] `docker compose ps` shows **healthy**

## 2.6 Confirm the extensions

```bash
make extensions
```

You should see a table of ~20 rows: `postgres_fdw`, `mysql_fdw`, `tds_fdw`,
`file_fdw`, `vector`, `pg_cron`, `pg_partman`, `pgaudit`, `pg_repack`,
`hypopg`, `pg_hint_plan`, `orafce`, `pg_stat_statements`, plus the core toolbox.

Full catalogue & usage: [doc 4 — Extensions](04-EXTENSIONS.md).

## 2.7 Connect

With `psql` inside the container:

```bash
make psql
```

From your host (needs a local `psql`/DBeaver/etc.):

```bash
psql "postgresql://local_dev:<password>@127.0.0.1:15409/local_db"
```

---

### Troubleshooting first boot

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Build fails on `mysql_fdw` | transient network / apt mirror | re-run `make build` |
| `port is already allocated` | 15409 in use | change `POSTGRES_HOST_PORT` in `.env`, `make up` |
| Container restarts in a loop | bad `postgresql.conf` edit | `make logs`, fix the config, `make restart` |
| Extensions missing | data volume pre-existed init | `make destroy && make up` (⚠️ wipes data) |

More in [doc 9 — Troubleshooting](09-TROUBLESHOOTING.md).

---

✅ Up and healthy? Continue to
[3. Configuration »](03-CONFIGURATION.md)
