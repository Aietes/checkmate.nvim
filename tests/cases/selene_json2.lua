return function(t, ctx)
  local cwd = t.abs(ctx.root .. '/tmp-selene')

  local parser_ctx = {
    cmd = 'selene --display-style Json2 .',
    title = 'selene',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({
      '{"type":"Diagnostic","severity":"Warning","code":"unused_variable","message":"f is defined, but never used","primary_label":{"filename":"lua/foo.lua","span":{"start_line":0,"start_column":15}}}',
      '{"type":"Diagnostic","severity":"Error","code":"undefined_variable","message":"`x` is not defined","primary_label":{"filename":"lua/foo.lua","span":{"start_line":1,"start_column":9}}}',
      '{"type":"Summary","errors":1,"warnings":1,"parse_errors":0}',
    }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed = ctx.state.parsers.selene(parser_ctx)
  t.expect(type(parsed) == 'table', 'selene parser should parse Json2 output')
  t.expect_eq(#parsed.items, 2, 'selene parser should produce two items')
  t.expect_eq(parsed.items[1].type, 'W', 'selene warning should map to W')
  t.expect_eq(parsed.items[1].lnum, 1, 'selene line should convert 0-based to 1-based')
  t.expect_eq(parsed.items[1].col, 16, 'selene column should convert 0-based to 1-based')
  t.expect(parsed.items[1].text:find('%[unused_variable%]') ~= nil, 'selene warning should include code')
  t.expect_eq(parsed.items[2].type, 'E', 'selene error should map to E')

  local clean_ctx = {
    cmd = 'selene --display-style Json2 .',
    title = 'selene',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = '{"type":"Summary","errors":0,"warnings":0,"parse_errors":0}',
    errorformat = vim.o.errorformat,
  }

  local parsed_clean = ctx.state.parsers.selene(clean_ctx)
  t.expect(type(parsed_clean) == 'table', 'selene parser should treat summary-only output as valid')
  t.expect_eq(#parsed_clean.items, 0, 'selene parser should return zero items for clean summary')
end
