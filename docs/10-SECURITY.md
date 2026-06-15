# 10. Security

> Even for local dev, a few habits prevent leaks and make the eventual jump to
> staging/production painless.

## 10.1 Secrets

- [ ] **`.env` is git-ignored** (it is — see `.gitignore`). Never commit it.
- [ ] Use a **strong, unique** `POSTGRES_PASSWORD` (the `openssl rand` snippet
      in [doc 2](02-INSTALLATION.md)).
- [ ] Don't paste real passwords into issues, screenshots, or commit messages.
- [ ] If a password leaks, rotate it:
      ```sql
      ALTER USER local_dev WITH PASSWORD 'new-strong-password';
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
