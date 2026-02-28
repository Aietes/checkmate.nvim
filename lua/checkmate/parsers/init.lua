local cargo = require 'checkmate.parsers.cargo'
local efm = require 'checkmate.parsers.efm'
local eslint = require 'checkmate.parsers.eslint'
local mixed = require 'checkmate.parsers.mixed'
local oxlint = require 'checkmate.parsers.oxlint'
local ts = require 'checkmate.parsers.ts'

local M = {}

---@param state checkmate.State
function M.register_builtin_parsers(state)
  state.parsers.oxlint = oxlint.parse
  state.parsers.eslint = eslint.parse
  state.parsers.efm = function(ctx)
    return efm.parse(ctx.combined, ctx.errorformat)
  end
  state.parsers.oxlint_json = oxlint.parse_json
  state.parsers.eslint_text = eslint.parse_text
  state.parsers.eslint_json = eslint.parse_json
  state.parsers.cargo_json = cargo.parse_json
  state.parsers.ts_text = ts.parse
  state.parsers.mixed_lint_json = function(ctx)
    return mixed.parse(ctx, {
      eslint = eslint,
      oxlint = oxlint,
      ts = ts,
    })
  end
end

return M
