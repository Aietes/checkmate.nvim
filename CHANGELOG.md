# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and this project uses Semantic Versioning.

## [Unreleased]

### Added
- Release automation script (`scripts/release.sh`)
- Help docs (`doc/checkmate.txt`) and health checks (`:checkhealth checkmate`)
- Headless test harness and parser-focused test cases
- Runtime version API (`check.VERSION`, `check.version()`)

## [0.1.0] - 2026-02-28

### Added
- Initial public release of `checkmate.nvim`
- Async command runner with quickfix-first workflow
- Built-in parsers for eslint, oxlint, cargo, ts_text, mixed_lint_json, and efm fallback
- Built-in presets (`oxlint`, `eslint`, `clippy`, `rust`, `tsc`, `nuxt`)
- User commands (`:Check`, `:CheckScript`, `:CheckPreset`)
