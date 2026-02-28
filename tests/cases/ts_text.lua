return function(t, ctx)
  local cwd = t.abs(ctx.root .. '/tmp-ts')
  local parser_ctx = {
    cmd = 'tsc --noEmit --pretty false',
    title = 'tsc',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({
      "src/main.ts(2,8): error TS2322: Type 'string' is not assignable to type 'number'.",
      "  The expected type comes from property 'age'.",
    }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed = ctx.state.parsers.ts_text(parser_ctx)
  t.expect(type(parsed) == 'table', 'ts_text should parse diagnostics')
  t.expect_eq(#parsed.items, 1, 'ts_text should produce one item')

  local item = parsed.items[1]
  t.expect(item.text:find('%[tsc%]') ~= nil, 'ts_text should tag item source')
  t.expect(item.text:find('The expected type comes from property') ~= nil, 'ts_text should append continuation lines')
end
