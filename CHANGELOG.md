# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and this project uses Semantic Versioning.

## [Unreleased]

### Added
- No unreleased entries yet.

## [0.1.2] - 2026-03-01

### Added
- Lua diagnostics support via built-in `luacheck` parser
- Built-in `lua` / `luacheck` presets (`:Check @lua`)
- Nix + direnv development environment support (`.envrc`, `flake.lock`)
- Project luacheck config (`.luacheckrc`) with Neovim globals

### Changed
- Lua preset command now targets project paths (`luacheck lua tests`)
- Runner no longer shows parser-fallback warnings when command is not found
- `efm` fallback entries without file targets are filtered from quickfix
- Core type annotations tightened for cleaner `lua_ls` diagnostics

### Fixed
- TypeScript/Nuxt parser handling for prefixed and multiline diagnostics
- `luacheck` parser handling for both coded and default output formats
- `resolve_cwd` always returns a concrete string path
- Miscellaneous `lua_ls` warnings across runner/parser/test modules

## [0.1.1] - 2026-02-28

### Added
- Release automation script (`scripts/release.sh`)
- Help docs (`doc/checkmate.txt`) and tags
- Health checks (`:checkhealth checkmate`)
- Headless test harness and parser-focused test cases
- Runtime version API (`check.VERSION`, `check.version()`)

## [0.1.0] - 2026-02-28

### Added
- Initial public release of `checkmate.nvim`
- Async command runner with quickfix-first workflow
- Built-in parsers for eslint, oxlint, cargo, ts_text, mixed_lint_json, and efm fallback
- Built-in presets (`oxlint`, `eslint`, `clippy`, `rust`, `tsc`, `nuxt`)
- User commands (`:Check`, `:CheckScript`, `:CheckPreset`)
