# Contributing

## Development Setup

- Neovim `0.10+`
- Git

Clone and run tests:

```bash
./scripts/test.sh
```

## Project Structure

- `lua/quickmate/` plugin source
- `doc/quickmate.txt` help docs
- `tests/` headless Neovim test suite
- `scripts/test.sh` test entrypoint
- `scripts/release.sh` release automation

## Pull Request Checklist

1. Keep behavior aligned with `doc/CONTRACT.md` (or update contract intentionally).
2. Add/adjust tests for behavioral changes.
3. Run:
   - `./scripts/test.sh`
4. Update docs when API/commands/config change:
   - `README.md`
   - `doc/quickmate.txt`
   - `CHANGELOG.md` (for user-visible changes)
5. Regenerate help tags:
   - `nvim --headless -u NONE "+helptags doc" +qa`

## Release Process

Releases use SemVer + git tags (`vX.Y.Z`).
`scripts/release.sh` requires a matching changelog section:
`## [X.Y.Z] - YYYY-MM-DD`

Create a release:

```bash
./scripts/release.sh 0.1.1
git push origin main
git push origin v0.1.1
```

Preview release steps:

```bash
./scripts/release.sh 0.1.1 --dry-run
```
