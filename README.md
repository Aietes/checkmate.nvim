# checkmate.nvim

Get project-wide diagnostics from linters, typecheckers, and analyzers in one consolidated quickfix list.

`checkmate.nvim` runs shell commands asynchronously, parses linter/typecheck/analyzer output, and populates the quickfix list with normalized entries. Neovim already has great tools for diagnostics in open buffers, like `nvim-lspconfig` (LSP), `nvim-lint`, `none-ls.nvim`, and formatter flows with `conform.nvim`; the gap is project-wide checking across all files with one consolidated quickfix list, which is especially useful in team collaboration and pre-PR validation.

## Features

- Async command execution via `vim.system`
- Quickfix-first workflow (`command -> parser -> quickfix`)
- Package manager aware script/exec command building (`pnpm`, `bun`, `npm`, `yarn`)
- Built-in parsers for:
  - `oxlint` JSON and text output
  - `eslint` JSON and text output
  - `luacheck` text diagnostics
  - `cargo --message-format=json` diagnostics
  - TypeScript/Nuxt text diagnostics
  - `errorformat` fallback for generic tools
- Mixed-output parser for scripts that combine multiple tools (for example `nuxt typecheck;oxlint;eslint`)
- Built-in command presets (`oxlint`, `eslint`, `clippy`, `rust`, `tsc`, `nuxt`, `lua`)
- Native `vim.notify` progress and completion messages

## Scope and Rationale

`checkmate.nvim` is intentionally focused on checks that produce diagnostics across a project:

- linters
- typecheckers
- analyzers

Formatters and auto-fix workflows (for example Prettier/Biome fix flows) are intentionally out of scope, since they are typically handled by formatter orchestration tools such as `conform.nvim`.

This keeps `checkmate.nvim` simple: one job, one output target (quickfix).

## Requirements

- Neovim `0.10+` (uses `vim.system` and modern `vim.fs` APIs)

## Health Check

```vim
:checkhealth checkmate
```

## What This Plugin Does Not Do

`checkmate.nvim` does not install or configure linters/typecheckers/analyzers for you.

Each project is expected to provide its own tools and configuration (for example via `package.json`, `Cargo.toml`, local config files, and installed binaries).

`checkmate.nvim` is responsible for:

- running your command
- parsing output
- writing quickfix entries

## Installation

### lazy.nvim

```lua
{
  'your-org/checkmate.nvim',
  -- optional: pin to a release tag
  -- version = '*',
  opts = {},
}
```

### Manual setup

```lua
require('checkmate').setup()
```

Help docs:

```vim
:help checkmate.nvim
```

If needed (manual installs), generate help tags:

```vim
:helptags ALL
```

## Commands

- `:Check <shell command>`
- `:Check @<preset-name>` (explicit preset shorthand)
- `:CheckScript <pnpm-script-name>`
- `:CheckPreset <name>`

Examples:

```vim
:Check oxlint
:Check @rust
:Check "pnpm exec nuxt typecheck"
:Check "cargo clippy --message-format=json"
:Check @lua
:CheckScript check
:CheckPreset tsc
```

## Mixed Output Checks (Recommended for JS/TS Monorepos)

For combined project checks, prefer one script that runs typecheck + multiple linters and let `:CheckScript` parse all diagnostics into one quickfix list.

Example `package.json`:

```json
{
  "scripts": {
    "check": "nuxt typecheck;oxlint . --format=json;eslint . -f json"
  }
}
```

Then run:

```vim
:CheckScript check
```

Why this pattern:

- `;` runs all steps even if one step fails, so you still get a complete quickfix list
- JSON output from `oxlint` and `eslint` is more reliable to parse than text output
- `mixed_lint_json` merges typecheck text diagnostics with embedded linter JSON payloads

## Built-in Presets

- `oxlint`: Fast JavaScript/TypeScript linter from the Oxc project.  
  Example command: `pnpm exec oxlint --format json .`  
  https://oxc.rs/docs/guide/usage/linter.html
- `eslint`: Widely used JavaScript/TypeScript linter with extensive plugin ecosystem.  
  Example command: `pnpm exec eslint -f json .`  
  https://eslint.org/
- `clippy`: Rust lint collection for catching common mistakes and improving code quality.  
  Example command: `cargo clippy --message-format=json`  
  https://doc.rust-lang.org/clippy/
- `rust`: Rust compiler check mode (`cargo check`) for fast compile-time diagnostics without building binaries.  
  Example command: `cargo check --message-format=json`  
  https://doc.rust-lang.org/cargo/commands/cargo-check.html
- `tsc`: TypeScript compiler typecheck mode (`--noEmit`) for TS diagnostics only.  
  Example command: `pnpm exec tsc --noEmit --pretty false`  
  https://www.typescriptlang.org/docs/handbook/compiler-options.html
- `nuxt`: Nuxt-specific typecheck command for Vue/Nuxt projects.  
  Example command: `pnpm exec nuxt typecheck`  
  https://nuxt.com/docs/api/commands/typecheck
- `lua`: Lua diagnostics via `luacheck`.  
  Example command: `luacheck lua tests`  
  https://github.com/lunarmodules/luacheck
  Uses project `.luacheckrc` (included) to recognize Neovim `vim.*` globals.

## Configuration

```lua
require('checkmate').setup({
  open_quickfix = 'on_items', -- 'on_items' | 'always' | 'never'
  default_errorformat = vim.o.errorformat,
  commands = true,
  package_manager = nil, -- 'pnpm' | 'bun' | 'npm' | 'yarn' | nil (auto)
  package_manager_priority = { 'pnpm', 'bun', 'npm', 'yarn' },
  presets = {
    check = {
      cmd = 'pnpm run check',
      parser = 'mixed_lint_json',
      title = 'project check',
    },
  },
})
```

Package manager detection order:

1. Explicit override from `run(..., { package_manager = ... })` or `run_script(..., { package_manager = ... })`
2. `setup({ package_manager = ... })`
3. Lockfile detection in project root (`pnpm-lock.yaml`, `bun.lock`/`bun.lockb`, `package-lock.json`, `yarn.lock`)
4. First executable found from `package_manager_priority`

## Package Manager Detection

For JS/TS commands (`:CheckScript` and manager-aware presets), `checkmate.nvim` resolves a package manager in this order:

1. Per-run override (`opts.package_manager`)
2. Global setup override (`setup({ package_manager = ... })`)
3. Project lockfiles:
   - `pnpm-lock.yaml` -> `pnpm`
   - `bun.lock` / `bun.lockb` -> `bun`
   - `package-lock.json` -> `npm`
   - `yarn.lock` -> `yarn`
4. First executable from `package_manager_priority` (default: `pnpm`, `bun`, `npm`, `yarn`)

Command translation examples:

- `run_script('check')` with `pnpm` -> `pnpm run check`
- `run_script('check')` with `bun` -> `bun run check`
- `@tsc` with `npm` -> `npx --no-install tsc --noEmit --pretty false`

## API

```lua
local check = require('checkmate')

check.VERSION
check.version()
check.setup(opts)
check.run(cmd, opts)
check.run_script(name, opts)
check.run_preset(name, opts)
check.register_parser(name, fn)
check.register_preset(name, preset)
```

## Versioning

`checkmate.nvim` uses SemVer and Git tags (standard for Neovim plugins).

- Source-of-truth runtime version: `require('checkmate').VERSION`
- Current version file: `VERSION`
- Release tags should be `vX.Y.Z` (for example `v0.1.0`)
- Repeatable release script: `./scripts/release.sh X.Y.Z`

Create a release (updates version files, runs tests, commits, tags):

```bash
./scripts/release.sh 0.1.1
git push origin main
git push origin v0.1.1
```

Preview release actions without changes:

```bash
./scripts/release.sh 0.1.1 --dry-run
```

## Parser Strategy

Parse order:

1. Explicit parser from `opts.parser`
2. Auto-detected parser by command content
3. Fallback parser `efm` (`errorformat`)

`mixed_lint_json` merges:

- TypeScript/Nuxt text diagnostics
- Embedded `oxlint` JSON payloads
- Embedded `eslint` JSON payloads

This allows one `:CheckScript check` command to collect all issues into one quickfix list.

## Notifications

Native `vim.notify` is used for:

- Running spinner while command executes
- Completion status (`no issues`, `<n> issue(s)`)
- Parser fallback warnings
- Execution/parser errors

## Extending

Register custom parsers:

```lua
require('checkmate').register_parser('my_tool', function(ctx)
  -- return { items = {...}, ok = true } or nil
end)
```

Register custom presets:

```lua
require('checkmate').register_preset('my_check', {
  cmd = 'pnpm run my:check',
  parser = 'mixed_lint_json',
  title = 'my check',
})
```

## Contributing Presets

Additional presets are welcome.

When opening a PR for a new preset, include:

- the tool command(s) for supported package managers (if JS/TS ecosystem)
- expected output format and parser used
- one real output sample (error and/or warning)
- a short note explaining why the preset fits the plugin scope (diagnostics-oriented checks)

Prefer presets that are:

- diagnostics-focused (lint/typecheck/analyzer)
- stable across common project setups
- parser-backed (structured JSON preferred when available)

## Testing

Run the built-in parser/registration tests with headless Neovim:

```bash
./scripts/test.sh
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development workflow and release steps.

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

## Design Principles

- Prefer native Neovim APIs (`vim.system`, `vim.fs.root`, quickfix APIs)
- Keep behavior predictable and quickfix-focused
- Avoid task-runner orchestration complexity
- Keep parser modules composable and small
