# 5. Resource Tuning

> The whole point: **Postgres must never destabilise your laptop**, no matter
> what query you run, even while Elasticsearch, Redis and NestJS are busy.

## 5.1 The two layers of protection

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1 — Docker hard caps (docker-compose.yml / .env)   │
│   mem_limit 1536M · cpus 2.0 · memswap 2048M · shm 256m  │
│   → the OS cgroup ENFORCES these. Postgres CANNOT exceed. │
├─────────────────────────────────────────────────────────┤
│ Layer 2 — postgresql.conf (config/)                       │
│   shared_buffers 256M · work_mem 16M · max_conns 50 ...    │
│   → keeps Postgres comfortably UNDER the Layer-1 ceiling.  │
└─────────────────────────────────────────────────────────┘
```

Layer 2 is sized to stay below Layer 1 even under worst-case concurrency, so the
container is rarely OOM-killed — but if something truly runs away, Layer 1 stops
it from taking the whole machine down.

## 5.2 Why these numbers (16 GB shared laptop)

Standard "production" advice says `shared_buffers = 25% of RAM` (≈4 GB here).
**We intentionally ignore that** — on a shared dev laptop you do *not* own the
RAM. Instead:

| Knob | Our value | Production-on-dedicated would say | Reason for ours |
|------|-----------|-----------------------------------|-----------------|
| container memory | 1536M | (no limit) | leave ≥10 GB for ES/Redis/NestJS/IDE/OS |
| `shared_buffers` | 256M | ~4 GB | small cache; rely on OS cache we share |
| `effective_cache_size` | 768M | ~12 GB | honest estimate of *our share* of cache |
| `work_mem` | 16M | 64M+ | 16M × sorts × 50 conns is bounded |
| `max_connections` | 50 | 100–200 | dev rarely needs more; pooler if so |
| `cpus` | 2.0 | all | keep threads free for other services |

### A quick worst-case memory sketch

```
shared_buffers ............... 256 MB
maintenance_work_mem (×2 av) . 256 MB
work_mem headroom (bounded) .. ~300 MB   (typical, not 50×16M simultaneously)
backends + wal + misc ........ ~300 MB
                               ---------
realistic peak ............... ~1.1 GB   →  fits under the 1536M cap ✅
```

## 5.3 Verify it in practice

```bash
make stats          # live: MEM USAGE / LIMIT and CPU %
```

You want `MEM USAGE` to sit well under `LIMIT` (1.5 GiB) during normal work.

```bash
free -h             # on the host: keep "available" > ~1 GB
docker stats        # all containers at once — see the whole picture
```

## 5.4 Rebalancing for your situation

**You closed Elasticsearch and want Postgres faster?** Temporarily bump in `.env`:

```env
PG_MEM_LIMIT=3072M
PG_CPU_LIMIT=4.0
```
and in `config/postgresql.conf`: `shared_buffers=512MB`, `work_mem=32MB`,
`effective_cache_size=1536MB`. Then `make up` (recreates with new caps) and
`make restart`.

**RAM is tight and the laptop is swapping?** Go the other way:

```env
PG_MEM_LIMIT=1024M
```
and `shared_buffers=192MB`, `max_connections=30`.

> Rule of thumb: keep `shared_buffers` ≈ 15–25% of `PG_MEM_LIMIT`, and ensure
> `PG_MEM_LIMIT` + the sum of your other services' appetites < total RAM − 2 GB.

## 5.5 Long-term hygiene

- [ ] **Autovacuum is on** and slightly aggressive (dev tables churn). Leave it.
- [ ] Run `make backup` regularly; prune old dumps in `./backups`.
- [ ] Watch image/log growth: logs are capped (`max-size: 10m`, 3 files).
- [ ] If `pgdata` grows large, occasionally `pg_repack` bloated tables.
- [ ] `make destroy` between unrelated projects to reclaim disk (wipes data).

---

✅ Next: plug it into your app →
[6. NestJS Integration »](06-NESTJS-INTEGRATION.md)
