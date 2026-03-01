# `checkmate` Contract (v1)

This document defines the initial API and behavior for a local utility that runs shell commands and parses output into the quickfix list.

## Goal

- Replace task-runner complexity with a single flow: `command -> parser -> quickfix`.
- Support generic shell commands and `pnpm` scripts.
- Work across linters, formatters, and analyzers via parser adapters.

## Engineering Principles

- Prefer native Neovim interfaces from the latest stable version before writing custom helpers.
- Prefer `vim.fs.root` for root detection over custom root-search logic.
- Prefer `vim.system` over custom async job wrappers.
- Prefer built-in quickfix APIs (`setqflist`, `getqflist`) over custom list state.
- Keep modules small and composable in a Folke-style layout:
  - one focused utility module
  - parser table separated from runner flow
  - minimal side effects and explicit setup
- Keep public API stable and small; avoid feature creep in v1.
- Use Lua type annotations for public functions, config tables, parser context, and result payloads.
- Use `snake_case` names and single-responsibility functions.
- Avoid hidden global state; store module-local state in one explicit table.
- Fail gracefully: parser exceptions should never break the run flow.

## Public API

`checkmate` exposes:

1. `setup(opts)`
2. `run(cmd, opts?)`
3. `run_script(name, opts?)` (sugar for `pnpm run <name>`)
4. `run_preset(name, opts?)`
5. `register_parser(name, parser_fn)`
6. `register_preset(name, preset_opts)`

## `setup(opts)`

`setup` sets defaults and registers user commands.

Options:

- `open_quickfix`: `'on_items' | 'always' | 'never'` (default: `'on_items'`)
- `default_errorformat`: `string | nil` (default: `vim.o.errorformat`)
- `commands`: `boolean` (default: `true`)
- `package_manager`: `'pnpm' | 'bun' | 'npm' | 'yarn' | nil` (default: auto-detect)
- `package_manager_priority`: `string[]` (default: `{'pnpm','bun','npm','yarn'}`)
- `presets`: `table<string, preset_opts>` (merged with built-ins)

No notifier injection exists in v1. Notifications always use `vim.notify`.

## `run(cmd, opts?)`

Runs `cmd` asynchronously with `vim.system`, captures `stdout` and `stderr`, parses output into quickfix entries, and sets quickfix.

`opts`:

- `title?: string`
- `cwd?: string`
- `env?: table<string, string>`
- `timeout_ms?: number`
- `package_manager?: 'pnpm' | 'bun' | 'npm' | 'yarn'`
- `parser?: string | fun(ctx): parser_result`
- `errorformat?: string`
- `open_quickfix?: 'on_items' | 'always' | 'never'`
- `on_complete?: fun(result)`

## `run_script(name, opts?)`

Equivalent to:

- command: `<pm> run <name>` resolved by package manager detection
- title default: `<pm> run <name>`
- parser default: `mixed_lint_json`

All `run` options still apply.

## `run_preset(name, opts?)`

Looks up a registered preset and runs it via `run`.

Behavior:

- preset defaults are merged with `opts`
- `opts` wins on conflicts
- unknown preset names notify with `ERROR`

## Parser Contract

Parser input `ctx`:

- `cmd: string`
- `title: string`
- `cwd: string`
- `stdout: string`
- `stderr: string`
- `combined: string` (`stdout .. "\n" .. stderr`)

Parser result:

- `{ items: vim.quickfix.entry[], ok?: boolean, message?: string }`

Behavior:

- If parser returns `nil` or `ok == false`, runner falls back to next parser.
- Final fallback parser is `efm` using `errorformat`.

## Built-in Parsers (v1)

1. `efm` (fallback parser)
2. `oxlint_json`
3. `eslint_json`
4. `cargo_json` (`cargo check` / `cargo clippy` with JSON output)
5. `luacheck` (luacheck text diagnostics)
6. `luacheck_text` (luacheck text parser alias)
7. `ts_text` (parses TypeScript/Nuxt style text diagnostics)
8. `mixed_lint_json` (merges `ts_text` diagnostics with embedded ESLint/Oxlint JSON payloads from mixed command output)
9. `oxlint` (json first, then text fallback)
10. `eslint_text` (eslint text format fallback)
11. `eslint` (json first, then text fallback)

## Preset Contract

Preset fields:

- `cmd: string | fun({ package_manager }): string`
- `title?: string`
- `parser?: string | fun(ctx): parser_result`
- `errorformat?: string`
- `cwd?: string`
- `env?: table<string, string>`
- `open_quickfix?: 'on_items' | 'always' | 'never'`

Built-in presets:

1. `oxlint`: manager-aware command, parser `oxlint`
2. `eslint`: manager-aware command, parser `eslint`
3. `clippy`: `cargo clippy --message-format=json`, parser `cargo_json`
4. `rust`: `cargo check --message-format=json`, parser `cargo_json`
5. `tsc`: manager-aware `tsc --noEmit --pretty false`, parser `ts_text`
6. `nuxt`: manager-aware `nuxt typecheck`, parser `ts_text`
7. `lua`: `luacheck lua tests`, parser `luacheck`
8. `luacheck`: `luacheck lua tests`, parser `luacheck`

Manager-aware JS/TS command mapping:

- `pnpm`: `pnpm exec <bin> ...`
- `bun`: `bunx <bin> ...`
- `npm`: `npx --no-install <bin> ...`
- `yarn`: `yarn <bin> ...`

## User Commands (when `commands = true`)

1. `:Check <shell command>`
   - explicit preset shorthand: `:Check @<preset>`
2. `:CheckScript <pnpm-script-name>`
3. `:CheckPreset <name>`

## Messaging Policy (v1)

Always use `vim.notify`:

- `INFO`
  - running spinner while command executes
  - `check: no issues (<title>)`
- `WARN`
  - `check: parser failed, used efm fallback (<title>)`
  - `check: <n> issue(s) (<title>)`
  - `check: failed (<title>), exit <code>: <reason>`
- `ERROR`
  - `check: failed to run (<title>): <reason>`
  - parser exception details (short, single-line)

Command-not-found behavior:
- If command execution returns "command not found", parser/fallback is skipped and quickfix stays empty.

Messages are intentionally brief and status-focused. Full command output remains in the parser context and completion result.

## Completion Result Contract

`on_complete(result)` receives:

- `cmd: string`
- `title: string`
- `code: integer`
- `signal: integer | nil`
- `stdout: string`
- `stderr: string`
- `combined: string`
- `items: vim.quickfix.entry[]`
- `parser_used: string`
- `duration_ms: integer`

## Non-goals for v1

- Task graphs / dependencies
- Task list UI / history browser
- Cancellation queue manager
- Diagnostics namespace synchronization (quickfix-first only)
