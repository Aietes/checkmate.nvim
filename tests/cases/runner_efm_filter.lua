return function(t)
  local checkmate = require 'checkmate'

  local done = false
  ---@type checkmate.RunResult|nil
  local result = nil

  checkmate.run("printf 'oops\\n'", {
    parser = 'efm',
    errorformat = '%m',
    open_quickfix = 'never',
    on_complete = function(res)
      result = res
      done = true
    end,
  })

  local ok = vim.wait(2000, function()
    return done
  end, 20)

  t.expect(ok, 'runner efm filter test should complete')
  t.expect(type(result) == 'table', 'runner efm filter test should return result')
  local run_result = result
  t.expect(type(run_result) == 'table', 'runner efm filter test should return typed result')
  if not run_result then
    error('runner efm filter test expected run_result', 0)
  end
  t.expect_eq(run_result.parser_used, 'efm', 'runner efm filter test should use efm parser')
  t.expect_eq(#run_result.items, 0, 'runner should ignore efm entries without file target')
end
