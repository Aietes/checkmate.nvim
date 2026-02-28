local M = {}

M.known_package_managers = {
  pnpm = true,
  bun = true,
  npm = true,
  yarn = true,
}

---@class checkmate.State
---@field open_quickfix checkmate.OpenQuickfixPolicy
---@field default_errorformat string
---@field commands boolean
---@field commands_registered boolean
---@field package_manager string|nil
---@field package_manager_priority string[]
---@field parsers table<string, fun(ctx: checkmate.ParserContext): checkmate.ParserResult|nil>
---@field presets table<string, checkmate.PresetOpts>
M.state = {
  open_quickfix = 'on_items',
  default_errorformat = vim.o.errorformat,
  commands = true,
  commands_registered = false,
  package_manager = nil,
  package_manager_priority = { 'pnpm', 'bun', 'npm', 'yarn' },
  parsers = {},
  presets = {},
}

return M
