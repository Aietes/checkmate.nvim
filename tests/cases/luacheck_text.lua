return function(t, ctx)
  local cwd = t.abs(ctx.root .. '/tmp-luacheck')
  local parser_ctx = {
    cmd = 'luacheck .',
    title = 'luacheck',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({
      'lua/foo.lua:4:7: (W113) accessing undefined variable bar',
      'lua/baz.lua:9: (E011) syntax error',
      '',
      'Total: 1 warning / 1 error in 2 files',
    }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed = ctx.state.parsers.luacheck(parser_ctx)
  t.expect(type(parsed) == 'table', 'luacheck parser should parse output')
  t.expect_eq(#parsed.items, 2, 'luacheck parser should produce two items')

  local first = parsed.items[1]
  t.expect_eq(first.type, 'W', 'luacheck warning should map to W')
  t.expect(first.text:find('%[luacheck%]') ~= nil, 'luacheck parser should tag source')

  local second = parsed.items[2]
  t.expect_eq(second.type, 'E', 'luacheck error should map to E')
  t.expect(second.text:find('%(E%)') == nil, 'luacheck error text should include full code, not single letter')
  t.expect(second.text:find('%(E011%)') ~= nil, 'luacheck error text should include luacheck code')

  local default_ctx = {
    cmd = 'luacheck .',
    title = 'luacheck',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({
      'Checking lua/checkmate/commands.lua                         2 warnings',
      'lua/checkmate/commands.lua:31:24: unused variable script_name',
      'lua/checkmate/commands.lua:42:7: setting non-standard global variable foo',
      '',
      'Total: 2 warnings / 0 errors in 1 file',
    }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed_default = ctx.state.parsers.luacheck(default_ctx)
  t.expect(type(parsed_default) == 'table', 'luacheck parser should parse default formatter output')
  t.expect_eq(#parsed_default.items, 2, 'luacheck parser should parse default formatter issues')
  t.expect_eq(parsed_default.items[1].type, 'W', 'default luacheck issues should map to warnings')

  local clean_ctx = {
    cmd = 'luacheck .',
    title = 'luacheck',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({
      'Checking lua/checkmate/commands.lua                         OK',
      'Checking lua/checkmate/runner.lua                           OK',
      '',
      'Total: 0 warnings / 0 errors in 2 files',
    }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed_clean = ctx.state.parsers.luacheck(clean_ctx)
  t.expect(type(parsed_clean) == 'table', 'luacheck parser should return success for clean output')
  t.expect_eq(#parsed_clean.items, 0, 'clean luacheck output should produce zero items without fallback')
end
