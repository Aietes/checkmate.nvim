return function(t, ctx)
  local cwd = t.abs(ctx.root .. '/tmp-oxlint')
  local parser_ctx = {
    cmd = 'oxlint --format json .',
    title = 'oxlint',
    cwd = cwd,
    stdout = [[{"diagnostics":[{"filename":"lib/a.ts","line":3,"column":7,"message":"bad pattern","severity":"warning","code":"rule-x"}]}]],
    stderr = '',
    combined = '',
    errorformat = vim.o.errorformat,
  }
  parser_ctx.combined = parser_ctx.stdout

  local parsed = ctx.state.parsers.oxlint_json(parser_ctx)
  t.expect(type(parsed) == 'table', 'oxlint_json should parse json payload')
  t.expect_eq(#parsed.items, 1, 'oxlint_json should produce one item')

  local item = parsed.items[1]
  t.expect_eq(item.type, 'W', 'oxlint_json should map warning severity to W')
  t.expect(item.text:find('%[oxlint%]') ~= nil, 'oxlint_json should tag item source')
end
