local M = {}

local function health_api()
  if vim.health then
    return vim.health
  end
  return require 'health'
end

function M.check()
  local health = health_api()
  local state = require('checkmate.state').state

  health.start 'checkmate.nvim'

  if vim.fn.has 'nvim-0.10' == 1 then
    health.ok('Neovim version is supported (>= 0.10)')
  else
    health.error('Neovim 0.10+ is required')
  end

  if type(vim.o.shell) == 'string' and vim.o.shell ~= '' then
    health.info(string.format('Configured shell: %s', vim.o.shell))
  else
    health.warn('No shell configured via vim.o.shell')
  end

  local available_pm = {}
  for _, pm in ipairs({ 'pnpm', 'bun', 'npm', 'yarn' }) do
    if vim.fn.executable(pm) == 1 then
      available_pm[#available_pm + 1] = pm
    end
  end

  if #available_pm > 0 then
    health.ok('Detected package managers: ' .. table.concat(available_pm, ', '))
  else
    health.warn('No JS/TS package managers found on PATH (pnpm/bun/npm/yarn)')
  end

  local parser_count = vim.tbl_count(state.parsers or {})
  local preset_count = vim.tbl_count(state.presets or {})

  if parser_count == 0 then
    health.warn('No parsers registered yet (call require("checkmate").setup())')
  else
    health.ok(string.format('Registered parsers: %d', parser_count))
  end

  if preset_count == 0 then
    health.warn('No presets registered yet (call require("checkmate").setup())')
  else
    health.ok(string.format('Registered presets: %d', preset_count))
  end

  health.info('Run :help checkmate.nvim for usage and API docs')
end

return M
