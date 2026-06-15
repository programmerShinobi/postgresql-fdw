# Contributing

Thanks for your interest in improving **postgresql-fdw**! This project aims to be
a clean, reusable, laptop-friendly PostgreSQL development setup. Contributions of
all sizes are welcome.

## Ways to contribute

- 🐛 Report a bug (use the issue templates)
- 💡 Propose a feature or a new optional service/extension
- 📖 Improve the docs (`docs/` and `README.md`)
- 🔧 Submit a fix or enhancement via a pull request

## Development setup

```bash
git clone https://github.com/programmerShinobi/postgresql-fdw.git
cd postgresql-fdw
make init        # copies .env.example -> .env AND installs the git hooks
# edit .env: set a strong POSTGRES_PASSWORD
make build
make up
make extensions  # sanity check
```

> `make init` installs the **pre-commit secret guard** (`scripts/git-hooks/`).
> Please keep it enabled — it blocks accidental commits of credentials or
> internal IPs.

## Ground rules

1. **Never commit secrets or internal infrastructure details.** Real values go
   in `.env` / `.env.source` (gitignored); commit only `*.example` templates.
   Run `make scan-secrets` if unsure.
2. **Keep the default lightweight.** New services must be opt-in behind a Docker
   Compose `profile` and carry `mem_limit` + `cpus` caps. Nothing new should run
   on a plain `make up`. See [docs/12-OPTIONAL-FEATURES.md](docs/12-OPTIONAL-FEATURES.md).
3. **Pin image versions** (no `:latest`) for reproducible builds.
4. **Document it.** A feature without a doc entry is incomplete.
5. **Match the surrounding style** in configs, SQL, and Makefile targets.

## Pull request checklist

- [ ] `docker compose config` passes (and with `--profile ...` if you touched a profile)
- [ ] `make build` succeeds; `make up && make extensions` works
- [ ] No secrets/IPs added (`make scan-secrets` clean)
- [ ] Docs updated (`README.md` and/or `docs/`)
- [ ] `CHANGELOG.md` updated under "Unreleased"

## Commit messages

Use clear, imperative summaries (e.g. `Add hypopg usage example`). Conventional
Commit prefixes (`feat:`, `fix:`, `docs:`, `chore:`) are welcome but not required.

## Code of Conduct

By participating you agree to uphold our
[Code of Conduct](CODE_OF_CONDUCT.md).
