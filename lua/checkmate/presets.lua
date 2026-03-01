local M = {}

---@param state checkmate.State
function M.register_builtin_presets(state)
  local function build_exec_command(pm, bin, args)
    local suffix = args and (' ' .. args) or ''
    if pm == 'bun' then
      return string.format('bunx %s%s', bin, suffix)
    end
    if pm == 'npm' then
      return string.format('npx --no-install %s%s', bin, suffix)
    end
    if pm == 'yarn' then
      return string.format('yarn %s%s', bin, suffix)
    end
    return string.format('pnpm exec %s%s', bin, suffix)
  end

  state.presets.oxlint = {
    cmd = function(ctx)
      return build_exec_command(ctx.package_manager, 'oxlint', '--format json .')
    end,
    title = 'oxlint',
    parser = 'oxlint',
  }
  state.presets.eslint = {
    cmd = function(ctx)
      return build_exec_command(ctx.package_manager, 'eslint', '-f json .')
    end,
    title = 'eslint',
    parser = 'eslint',
  }
  state.presets.clippy = {
    cmd = 'cargo clippy --message-format=json',
    title = 'clippy',
    parser = 'cargo_json',
    env = { SQLX_OFFLINE = 'true' },
  }
  state.presets.rust = {
    cmd = 'cargo check --message-format=json',
    title = 'cargo check',
    parser = 'cargo_json',
    env = { SQLX_OFFLINE = 'true' },
  }
  state.presets.tsc = {
    cmd = function(ctx)
      return build_exec_command(ctx.package_manager, 'tsc', '--noEmit --pretty false')
    end,
    title = 'tsc',
    parser = 'ts_text',
  }
  state.presets.nuxt = {
    cmd = function(ctx)
      return build_exec_command(ctx.package_manager, 'nuxt', 'typecheck')
    end,
    title = 'nuxt typecheck',
    parser = 'ts_text',
  }
  state.presets.lua = {
    cmd = 'luacheck lua tests',
    title = 'luacheck',
    parser = 'luacheck',
  }
  state.presets.luacheck = {
    cmd = 'luacheck lua tests',
    title = 'luacheck',
    parser = 'luacheck',
  }
end

return M
