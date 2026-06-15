<!-- Thanks for contributing! Keep the default lightweight and never commit secrets. -->

## Summary

<!-- What does this PR do and why? -->

## Type of change

- [ ] 🐛 Bug fix
- [ ] ✨ New feature (extension / optional service / config)
- [ ] 📖 Documentation
- [ ] 🔧 Chore / refactor

## Checklist

- [ ] `docker compose config` passes (and `--profile ...` if a profile changed)
- [ ] `make build` succeeds; `make up && make extensions` works
- [ ] New services are **opt-in** behind a compose profile with `mem_limit`/`cpus` caps
- [ ] Image tags are pinned (no `:latest`)
- [ ] No secrets or internal IPs added — `make scan-secrets` is clean
- [ ] Docs updated (`README.md` and/or `docs/`)
- [ ] `CHANGELOG.md` updated under **Unreleased**

## Notes for reviewers

<!-- Anything specific you'd like feedback on -->
