local cargo = require 'quickmate.parsers.cargo'
local efm = require 'quickmate.parsers.efm'
local eslint = require 'quickmate.parsers.eslint'
local luacheck = require 'quickmate.parsers.luacheck'
local mixed = require 'quickmate.parsers.mixed'
local oxlint = require 'quickmate.parsers.oxlint'
local selene = require 'quickmate.parsers.selene'
local ts = require 'quickmate.parsers.ts'

local M = {}

---@param state quickmate.State
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
  state.parsers.luacheck = luacheck.parse
  state.parsers.luacheck_text = luacheck.parse_text
  state.parsers.selene = selene.parse
  state.parsers.selene_json2 = selene.parse_json2
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
