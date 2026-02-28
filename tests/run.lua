local root = vim.fn.getcwd()
package.path = table.concat({
  root .. '/?.lua',
  root .. '/lua/?.lua',
  root .. '/lua/?/init.lua',
  package.path,
}, ';')

local checkmate = require 'checkmate'
local state = require('checkmate.state').state
local t = require 'tests.lib.harness'

checkmate.setup({ commands = false })

local case_files = vim.fn.globpath(root .. '/tests/cases', '*.lua', false, true)
table.sort(case_files)

local executed = 0
for _, path in ipairs(case_files) do
  local module_name = path:gsub('^' .. vim.pesc(root .. '/'), ''):gsub('%.lua$', ''):gsub('/', '.')
  local case_fn = require(module_name)
  case_fn(t, { root = root, state = state })
  executed = executed + 1
end

print(string.format('checkmate tests passed (%d files, %d assertions)', executed, t.assertions))
