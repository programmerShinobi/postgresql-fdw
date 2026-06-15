# 6. NestJS Integration

> Wiring this database into a NestJS backend running on the **same host**,
> next to Elasticsearch and Redis.

## 6.1 Connection details

```
Host:     127.0.0.1
Port:     15409
User:     local_dev
Password: <your .env value>
Database: local_db
URL:      postgresql://local_dev:<password>@127.0.0.1:15409/local_db
```

Put it in your NestJS app's `.env` (separate from this repo's `.env`):

```env
DATABASE_URL=postgresql://local_dev:<password>@127.0.0.1:15409/local_db
```

## 6.2 With TypeORM

```ts
// app.module.ts
TypeOrmModule.forRoot({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  autoLoadEntities: true,
  synchronize: false,          // use migrations, even in dev
  // Keep the pool small — Postgres max_connections is 50 and shared.
  extra: { max: 10, idleTimeoutMillis: 30000 },
});
```

## 6.3 With Prisma

```prisma
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

```env
# Cap the pool so NestJS doesn't exhaust connections.
DATABASE_URL="postgresql://local_dev:<password>@127.0.0.1:15409/local_db?connection_limit=10&pool_timeout=20"
```

Enable extensions you use (e.g. pgvector) in a migration:

```prisma
// already created by this repo, but Prisma can manage them too:
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["postgresqlExtensions"]
}
datasource db {
  provider   = "postgresql"
  url        = env("DATABASE_URL")
  extensions = [vector, pg_trgm, uuid_ossp(map: "uuid-ossp")]
}
```

## 6.4 Connection-pool sizing (important on a shared laptop)

`max_connections = 50` is shared by **all** clients. If you run NestJS in watch
mode (which may spawn extra connections), plus a migration tool, plus a GUI, you
can exhaust it. Guidance:

- Keep each app pool **≤ 10**.
- For many short-lived connections, add **PgBouncer** in front (transaction
  pooling). A drop-in service can be added to `docker-compose.yml` later.
- Symptoms of exhaustion: `FATAL: sorry, too many clients already`. Fix: lower
  app pool size, or raise `max_connections` (costs RAM — see [doc 5](05-RESOURCE-TUNING.md)).

## 6.5 Running NestJS itself in Docker?

If your NestJS service is also a Compose service and you want it on the **same
Docker network**, attach it to this repo's network and use the **service name**
instead of `127.0.0.1`:

```yaml
# in your app's compose file
services:
  api:
    networks: [local_net]
    environment:
      DATABASE_URL: postgresql://local_dev:<password>@local-postgres:5432/local_db
networks:
  local_net:
    external: true
    name: local_net
```

> Inside the Docker network the port is **5432** (container port), not 15409.

## 6.6 Vector search from NestJS (pgvector quick example)

```sql
CREATE TABLE documents (
  id        bigserial PRIMARY KEY,
  content   text,
  embedding vector(1536)
);
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

```ts
// nearest neighbours
await dataSource.query(
  `SELECT id, content FROM documents ORDER BY embedding <=> $1 LIMIT 5`,
  [`[${embedding.join(',')}]`],
);
```

---

✅ Next: never lose data →
[7. Backup & Restore »](07-BACKUP-RESTORE.md)
