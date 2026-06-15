# 10. Security

> Even for local dev, a few habits prevent leaks and make the eventual jump to
> staging/production painless.

## 10.1 Secret management (the standard this repo follows)

**Golden rule: no credential — and no internal hostname/IP — ever enters git.**

How it's enforced here:

- [ ] **Real secrets live only in gitignored files**: `.env` (target DB) and
      `.env.source` (the DB you import FROM). Only the `*.example` templates,
      which contain placeholders, are committed.
- [ ] **`.gitignore` is broad**: `.env`, `.env.*`, `*.env`, `*.key`, `*.pem`,
      `*.secret`, `secrets/`, and all backup dumps (dumps embed FDW credentials).
- [ ] **A pre-commit guard blocks leaks** before they happen. Install it once:
      ```bash
      make hooks          # copies scripts/git-hooks/pre-commit into .git/hooks
      ```
      It rejects a commit that adds a private IP (10.x / 172.16–31.x / 192.168.x),
      a `postgres://user:pass@…` URI, a secret file, or a hardcoded password.
      Dry-run anytime with `make scan-secrets`. Override (rarely) with
      `git commit --no-verify`.
- [ ] **Migration scripts read `.env.source`** — never pass passwords on the
      command line (they'd land in your shell history).
- [ ] Use a **strong, unique** `POSTGRES_PASSWORD` (the `openssl rand` snippet
      in [doc 2](02-INSTALLATION.md)).
- [ ] Don't paste real passwords/hosts into issues, screenshots, or commit messages.

### If a credential was ever exposed — rotate it

Because this DB integrates several others via FDW, a leak of the Postgres
superuser can cascade. Rotate promptly:

```sql
-- the Postgres role
ALTER USER local_dev WITH PASSWORD 'new-strong-password';
```
Also rotate, at the source/remote side, **any credential that was visible**:
the source database's superuser password, and the remote MySQL/SQL Server logins stored in
the FDW user mappings. Update the mappings afterwards:
```sql
ALTER USER MAPPING FOR <role> SERVER <srv> OPTIONS (SET password 'new-remote-pw');
```

## 10.2 Authentication

- [ ] Host auth uses **`scram-sha-256`** (configured), not the legacy `md5`.
- [ ] `password_encryption = scram-sha-256` in `postgresql.conf`.

## 10.3 Network exposure

- [ ] In dev the port is published to **localhost** (`15409`). It's reachable by
      anything on your machine — fine for a personal laptop.
- [ ] On shared networks, bind to loopback explicitly in `docker-compose.yml`:
      ```yaml
      ports:
        - "127.0.0.1:15409:5432"
      ```
- [ ] In production, **do not publish the port** at all — keep Postgres on a
      private Docker/overlay network ([doc 8](08-DEPLOYMENT.md)).

## 10.4 Least privilege

- [ ] Your app ideally connects as a **non-superuser** role with only the grants
      it needs, not as `local_dev` (the superuser). A read-only role
      (`local_readonly`) is created for you as a starting point.
- [ ] Create a dedicated app role:
      ```sql
      CREATE ROLE app_user LOGIN PASSWORD 'strong';
      GRANT CONNECT ON DATABASE local_db TO app_user;
      GRANT USAGE ON SCHEMA app TO app_user;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_user;
      ```

## 10.5 Foreign Data Wrapper credentials

- [ ] FDW `USER MAPPING` stores remote credentials in the catalog. Treat the DB
      as sensitive. Prefer least-privilege remote accounts.
- [ ] Don't point FDW servers at production from a dev box without authorization.

## 10.6 Auditing

- [ ] `pgaudit` is installed. Enable targeted logging when you need an audit
      trail:
      ```sql
      ALTER SYSTEM SET pgaudit.log = 'write, ddl';
      SELECT pg_reload_conf();
      ```

## 10.7 Updates

- [ ] Rebuild periodically to pick up base-image security patches:
      ```bash
      docker compose pull        # refresh base layers where applicable
      make build
      make up
      ```
- [ ] Pin versions for reproducibility; bump deliberately and test.

## 10.8 Backups are a security control too

- [ ] Tested restores ([doc 7](07-BACKUP-RESTORE.md)) protect against ransomware
      and fat-finger `DROP`s.
- [ ] Store off-machine copies of important dumps; they contain real data —
      protect them accordingly.

---

🎉 You've reached the end. Back to the [README »](../README.md) or the
[master checklist](../README.md#-master-checklist).
