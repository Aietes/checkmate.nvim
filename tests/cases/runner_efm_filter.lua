return function(t, _ctx)
  local checkmate = require 'checkmate'

  local done = false
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
  t.expect_eq(result.parser_used, 'efm', 'runner efm filter test should use efm parser')
  t.expect_eq(#result.items, 0, 'runner should ignore efm entries without file target')
end
