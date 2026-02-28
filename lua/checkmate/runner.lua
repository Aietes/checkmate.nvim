local progress_notify = require 'checkmate.progress'
local state_mod = require 'checkmate.state'
local util = require 'checkmate.util'

local M = {}

local state = state_mod.state
local known_package_managers = state_mod.known_package_managers

---@param cmd string
---@return string|nil
local function auto_parser_for_command(cmd)
  local lower = cmd:lower()
  if lower:match 'oxlint' then
    return 'oxlint'
  end
  if lower:match 'eslint' then
    return 'eslint'
  end
  if lower:match 'cargo' and lower:match '%-%-message%-format%s*=%s*json' then
    return 'cargo_json'
  end
  if lower:match 'tsc' or lower:match 'nuxt%s+typecheck' then
    return 'ts_text'
  end
  return nil
end

---@param title string
---@param items vim.quickfix.entry[]
---@param open_policy checkmate.OpenQuickfixPolicy
local function apply_quickfix(title, items, open_policy)
  vim.fn.setqflist({}, 'r', { title = title, items = items })
  if open_policy == 'always' or (open_policy == 'on_items' and #items > 0) then
    vim.cmd 'copen'
  end
end

---@param cmd string
---@param opts checkmate.RunOpts|nil
---@return string
local function resolve_cwd(cmd, opts)
  if opts and opts.cwd and opts.cwd ~= '' then
    return opts.cwd
  end
  if cmd:match 'cargo' then
    local bufname = vim.api.nvim_buf_get_name(0)
    local start_path = (type(bufname) == 'string' and bufname ~= '') and bufname or vim.uv.cwd()
    local buffer_root = vim.fs.root(start_path, { 'Cargo.toml' })
    if buffer_root then
      return buffer_root
    end

    local cwd = vim.uv.cwd()
    local cwd_root = vim.fs.root(cwd, { 'Cargo.toml' })
    if cwd_root then
      return cwd_root
    end

    local nested = vim.fs.find('Cargo.toml', { path = cwd, type = 'file', limit = 2 })
    if #nested == 1 then
      return vim.fs.dirname(nested[1])
    end

    return vim.fs.root(0, { '.git' }) or cwd
  end
  if cmd:match 'pnpm' or cmd:match 'npm' or cmd:match 'yarn' or cmd:match 'bun' then
    return vim.fs.root(0, { 'package.json', '.git' }) or vim.uv.cwd()
  end
  return vim.fs.root(0, { '.git' }) or vim.uv.cwd()
end

---@param path string
---@return boolean
local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

---@param cwd string
---@return string|nil
local function detect_package_manager(cwd)
  if exists(vim.fs.joinpath(cwd, 'pnpm-lock.yaml')) and vim.fn.executable('pnpm') == 1 then
    return 'pnpm'
  end
  if (exists(vim.fs.joinpath(cwd, 'bun.lock')) or exists(vim.fs.joinpath(cwd, 'bun.lockb'))) and vim.fn.executable('bun') == 1 then
    return 'bun'
  end
  if exists(vim.fs.joinpath(cwd, 'package-lock.json')) and vim.fn.executable('npm') == 1 then
    return 'npm'
  end
  if exists(vim.fs.joinpath(cwd, 'yarn.lock')) and vim.fn.executable('yarn') == 1 then
    return 'yarn'
  end
  for _, pm in ipairs(state.package_manager_priority) do
    if vim.fn.executable(pm) == 1 then
      return pm
    end
  end
  return nil
end

---@param cwd string
---@param pm_override string|nil
---@return string|nil
local function resolve_package_manager(cwd, pm_override)
  local pm = pm_override or state.package_manager
  if type(pm) == 'string' and known_package_managers[pm] then
    if vim.fn.executable(pm) == 1 then
      return pm
    end
    vim.notify(string.format('check: package manager "%s" not executable', pm), vim.log.levels.WARN)
  end
  return detect_package_manager(cwd)
end

---@param pm string
---@param script string
---@return string
local function build_script_command(pm, script)
  local escaped = vim.fn.shellescape(script)
  if pm == 'bun' then
    return 'bun run ' .. escaped
  end
  if pm == 'npm' then
    return 'npm run ' .. escaped
  end
  if pm == 'yarn' then
    return 'yarn ' .. escaped
  end
  return 'pnpm run ' .. escaped
end

---@param parser_name string|nil
---@param parser_fn fun(ctx: checkmate.ParserContext): checkmate.ParserResult|nil
---@param ctx checkmate.ParserContext
---@return checkmate.ParserResult|nil
---@return string
---@return boolean
local function safe_parse(parser_name, parser_fn, ctx)
  local ok, result = pcall(parser_fn, ctx)
  if not ok then
    vim.notify(
      string.format('check: parser crashed (%s): %s', parser_name or 'custom', util.strip_newlines(tostring(result))),
      vim.log.levels.ERROR
    )
    return nil, parser_name or 'custom', true
  end
  if type(result) == 'table' and type(result.items) == 'table' and result.ok ~= false then
    result.items = util.normalize_items(result.items, ctx.cwd)
    return result, parser_name or 'custom', false
  end
  return nil, parser_name or 'custom', false
end

---@param cmd string
---@param opts checkmate.RunOpts
---@return string|nil
---@return fun(ctx: checkmate.ParserContext): checkmate.ParserResult|nil
local function resolve_explicit_parser(cmd, opts)
  if type(opts.parser) == 'function' then
    return 'custom', opts.parser
  end
  if type(opts.parser) == 'string' then
    local parser = state.parsers[opts.parser]
    if parser then
      return opts.parser, parser
    end
    vim.notify(string.format('check: unknown parser "%s", using fallback', opts.parser), vim.log.levels.WARN)
    return nil, nil
  end

  local auto = auto_parser_for_command(cmd)
  if auto and state.parsers[auto] then
    return auto, state.parsers[auto]
  end
  return nil, nil
end

---@param parser_name string
---@param parser_fn fun(ctx: checkmate.ParserContext): checkmate.ParserResult|nil
---@param ctx checkmate.ParserContext
---@return checkmate.ParserResult
---@return string
local function parse_with_fallback(parser_name, parser_fn, ctx)
  local used_fallback = false

  if parser_fn then
    local parsed, used_name, crashed = safe_parse(parser_name, parser_fn, ctx)
    if parsed then
      return parsed, used_name
    end
    if not crashed then
      used_fallback = true
    end
  end

  local fallback = state.parsers.efm
  local parsed, _, _ = safe_parse('efm', fallback, ctx)
  if not parsed then
    parsed = { items = {}, ok = true }
  end
  if used_fallback then
    vim.notify(string.format('check: parser failed, used efm fallback (%s)', ctx.title), vim.log.levels.WARN)
  end
  return parsed, 'efm'
end

---@param code integer
---@param output string
---@return boolean
local function is_command_not_found(code, output)
  local text = output:lower()
  if code == 127 then
    return true
  end
  if text:match 'command not found' then
    return true
  end
  if text:match 'not recognized as an internal or external command' then
    return true
  end
  return false
end

---@param cmd string
---@param opts checkmate.RunOpts|nil
function M.run(cmd, opts)
  cmd = util.normalize_command_input(cmd)
  if cmd == '' then
    vim.notify('check: missing command', vim.log.levels.ERROR)
    return
  end
  opts = opts or {}
  local title = opts.title or cmd
  local cwd = resolve_cwd(cmd, opts)
  local errorformat = opts.errorformat or state.default_errorformat or vim.o.errorformat
  local open_policy = opts.open_quickfix or state.open_quickfix
  local started_at = vim.uv.hrtime()
  local parser_name, parser_fn = resolve_explicit_parser(cmd, opts)

  local progress = progress_notify.start({
    id_prefix = 'check_',
    title = title,
    message = 'running check',
    level = vim.log.levels.INFO,
  })

  local shell_cmd = { vim.o.shell, vim.o.shellcmdflag, cmd }
  local ok, err = pcall(vim.system, shell_cmd, {
    text = true,
    cwd = cwd,
    env = opts.env,
    timeout = opts.timeout_ms,
  }, function(res)
    local stdout = res.stdout or ''
    local stderr = res.stderr or ''
    local combined = stdout
    if combined ~= '' and stderr ~= '' then
      combined = combined .. '\n' .. stderr
    elseif stderr ~= '' then
      combined = stderr
    end

    vim.schedule(function()
      local ctx = {
        cmd = cmd,
        title = title,
        cwd = cwd,
        stdout = stdout,
        stderr = stderr,
        combined = util.strip_ansi(combined),
        errorformat = errorformat,
      }

      local parser_result, parser_used = parse_with_fallback(parser_name, parser_fn, ctx)
      local items = parser_result.items or {}
      local duration_ms = math.floor((vim.uv.hrtime() - started_at) / 1e6)
      local command_missing = is_command_not_found(res.code, combined)

      if command_missing then
        items = {}
      end

      apply_quickfix(title, items, open_policy)

      if command_missing then
        progress_notify.finish(
          progress,
          string.format('check: failed to run (%s): command not found', title),
          vim.log.levels.ERROR
        )
      elseif #items > 0 then
        progress_notify.finish(progress, string.format('check: %d issue(s) (%s)', #items, title), vim.log.levels.WARN)
      elseif res.code == 0 then
        progress_notify.finish(progress, string.format('check: no issues (%s)', title), vim.log.levels.INFO)
      else
        local reason = util.first_nonempty_line(combined)
        local lower_reason = reason:lower()
        if cmd:match 'cargo' then
          if lower_reason:match 'could not find `cargo.toml`' then
            reason = string.format('Cargo.toml not found from cwd: %s', cwd)
          elseif lower_reason:match 'no targets specified in the manifest' then
            reason = 'Cargo.toml has no build targets in selected directory'
          end
        end
        progress_notify.finish(
          progress,
          string.format('check: failed (%s), exit %d%s', title, res.code, reason ~= '' and ': ' .. reason or ''),
          vim.log.levels.WARN
        )
      end

      if opts.on_complete then
        opts.on_complete({
          cmd = cmd,
          title = title,
          code = res.code,
          signal = res.signal,
          stdout = stdout,
          stderr = stderr,
          combined = combined,
          items = items,
          parser_used = parser_used,
          duration_ms = duration_ms,
        })
      end
    end)
  end)

  if not ok then
    progress_notify.stop(progress)
    vim.notify(
      string.format('check: failed to run (%s): %s', title, util.strip_newlines(tostring(err))),
      vim.log.levels.ERROR
    )
  end
end

---@param name string
---@param opts checkmate.RunOpts|nil
function M.run_script(name, opts)
  if type(name) ~= 'string' or name == '' then
    vim.notify('check: missing script name', vim.log.levels.ERROR)
    return
  end
  opts = opts or {}
  local cwd = opts.cwd or (vim.fs.root(0, { 'package.json', '.git' }) or vim.uv.cwd())
  local package_manager = resolve_package_manager(cwd, opts.package_manager)
  if not package_manager then
    vim.notify('check: no package manager found (pnpm/bun/npm/yarn)', vim.log.levels.ERROR)
    return
  end
  opts.title = opts.title or string.format('%s run %s', package_manager, name)
  opts.cwd = cwd
  opts.parser = opts.parser or 'mixed_lint_json'
  M.run(build_script_command(package_manager, name), opts)
end

---@param name string
---@param opts checkmate.RunOpts|nil
function M.run_preset(name, opts)
  local preset = state.presets[name]
  if not preset then
    vim.notify(string.format('check: unknown preset "%s"', name), vim.log.levels.ERROR)
    return
  end

  local cwd = (opts and opts.cwd) or preset.cwd or (vim.fs.root(0, { 'package.json', '.git' }) or vim.uv.cwd())
  local package_manager = resolve_package_manager(cwd, opts and opts.package_manager or nil)
  if not package_manager then
    package_manager = 'pnpm'
  end

  local cmd = type(preset.cmd) == 'function' and preset.cmd({ package_manager = package_manager, cwd = cwd }) or preset.cmd
  if type(cmd) ~= 'string' or cmd == '' then
    vim.notify(string.format('check: invalid preset command "%s"', name), vim.log.levels.ERROR)
    return
  end

  local merged = vim.tbl_deep_extend('force', preset, opts or {})
  merged.cmd = nil
  merged.cwd = merged.cwd or resolve_cwd(cmd, merged)
  M.run(cmd, merged)
end

return M
