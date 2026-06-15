# 1. Requirements

> Goal: confirm your machine can run this **alongside** your other heavy
> services without trouble — short-term (today's dev session) and long-term
> (weeks of multitasking).

## 1.1 Software prerequisites

- [ ] **Docker Engine ≥ 24** — check: `docker --version`
- [ ] **Docker Compose v2** (the `docker compose` subcommand) — check: `docker compose version`
- [ ] **GNU Make** (optional but recommended) — check: `make --version`
- [ ] **Git** — to clone & version this repo
- [ ] Your user can run Docker **without `sudo`**. On this laptop `faqih` is
      **not** in the `docker` group yet, so docker commands currently need
      `sudo`. Fix it once (recommended) so `make` works cleanly:
      ```bash
      sudo usermod -aG docker $USER
      # then log out and back in (or: newgrp docker) for it to take effect
      docker run --rm hello-world   # verify it works without sudo
      ```
      If you'd rather not, prefix every docker/make command with `sudo` — but
      the `Makefile` assumes the group setup above.

> This setup was validated on **elementary OS 8 (Ubuntu base)** with
> **Docker 29.x** and **Compose v5.x** — newer than the minimums above, so you're fine.

## 1.2 Hardware budget — your laptop

Reference machine this repo is tuned for:

| Component | Spec | Implication |
|-----------|------|-------------|
| CPU | Intel i7-1185G7 — 4 cores / 8 threads | Postgres capped at **2.0 CPUs** |
| RAM | 16 GB total | Postgres capped at **~1.5 GB** hard limit |
| Swap | ~4 GB | Thin — avoid memory pressure |
| Disk | 230 GB NVMe SSD (159 GB free) | Plenty; SSD-aware planner settings |
| OS | elementary OS 8 | Linux cgroups honour the caps |

### The RAM reality check

On a typical dev day you may be running **all of these at once**:

| Service | Rough RAM appetite |
|---------|--------------------|
| Elasticsearch (1 node) | 1–2 GB (JVM heap + off-heap) |
| Redis | 100–500 MB |
| NestJS (dev, watch mode) | 400–800 MB |
| VS Code + extensions | 1–2 GB |
| Browser / Chrome | 1–3 GB |
| **This PostgreSQL** | **capped at ~1.5 GB** |
| OS + the rest | ~2 GB |

That already approaches 16 GB. The hard caps in `docker-compose.yml` are the
**safety net**: even a runaway query cannot make Postgres balloon and OOM-kill
your other apps. See [doc 5 — Resource Tuning](05-RESOURCE-TUNING.md) for the math.

- [ ] You have at least **~2 GB of RAM headroom** before starting Postgres
      (check with `free -h`). If not, close something or lower `PG_MEM_LIMIT`.

## 1.3 Disk requirements

- [ ] **~2 GB** free for the built image (PG17 + compiled extensions).
- [ ] Additional space for your data volume (`local_pgdata`) and `./backups`.

## 1.4 Network / ports

- [ ] Host port **15409** is free (or pick another via `POSTGRES_HOST_PORT`).
      Check: `ss -ltnp | grep 15409` (should print nothing).

---

✅ When every box above is ticked, continue to
[2. Installation »](02-INSTALLATION.md)
