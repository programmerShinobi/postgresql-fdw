# 8. Deployment

> This repo is optimised for **laptop development**. Here's how to evolve the
> same setup toward staging/production safely and scalably.

## 8.1 What changes from dev → prod

| Concern | Dev (this repo) | Production |
|---------|-----------------|------------|
| Resource caps | tiny, shared laptop | size to the dedicated host |
| `shared_buffers` | 256M | ~25% of dedicated RAM |
| `effective_cache_size` | 768M | ~50–75% of RAM |
| `max_connections` | 50 | sized + **PgBouncer** in front |
| Password | `.env` file | a secrets manager (Vault/SOPS/Docker secrets) |
| Network exposure | localhost:15409 | private network only, TLS on |
| Backups | manual/cron | automated + offsite + tested restores |
| HA | none | replica(s) + failover |
| Monitoring | `make stats` | Prometheus `postgres_exporter` + alerts |

## 8.2 Environment-specific overrides

Keep this repo's `docker-compose.yml` as the base and layer an override file:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

`docker-compose.prod.yml` (example skeleton):

```yaml
services:
  postgres:
    restart: always
    ports: []                      # do NOT publish to host; internal only
    mem_limit: 8g
    cpus: 6.0
    shm_size: 1g
    environment:
      POSTGRES_HOST_AUTH_METHOD: scram-sha-256
    # mount a prod-tuned config instead
    volumes:
      - ./config/postgresql.prod.conf:/etc/postgresql/postgresql.conf:ro
```

Create `config/postgresql.prod.conf` from the dev one with prod-scale memory.

## 8.3 Secrets

Stop shipping passwords in `.env`. Use Docker secrets:

```yaml
secrets:
  pg_password:
    external: true
services:
  postgres:
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/pg_password
    secrets: [pg_password]
```

## 8.4 TLS

Generate/obtain a server cert and enable in `postgresql.conf`:

```
ssl = on
ssl_cert_file = '/etc/postgresql/certs/server.crt'
ssl_key_file  = '/etc/postgresql/certs/server.key'
```

Require it in `pg_hba.conf` with `hostssl` rules. Clients then use `sslmode=require`.

## 8.5 Connection pooling (scalability)

Add **PgBouncer** as a sidecar service in transaction-pooling mode and point
apps at it instead of Postgres directly. This lets hundreds of app connections
share a small Postgres `max_connections` — the standard scaling pattern.

## 8.6 High availability (when you outgrow one node)

- **Patroni** + etcd/Consul for automated failover, or a managed Postgres.
- Streaming replication is already enabled (`wal_level = replica`).
- Consider managed services (RDS, Cloud SQL, Crunchy, Aiven) to offload ops.

## 8.7 Pre-deploy checklist

- [ ] Prod config sized to the real host (not laptop values)
- [ ] Passwords via secrets manager, not `.env`
- [ ] Postgres **not** published to the public internet
- [ ] TLS enabled and required
- [ ] Automated, **tested** backups + retention
- [ ] Monitoring + alerting wired up
- [ ] PgBouncer in front for connection scaling
- [ ] Extension list reviewed (drop anything unused → smaller attack surface)

---

✅ Next: when things break →
[9. Troubleshooting »](09-TROUBLESHOOTING.md)
