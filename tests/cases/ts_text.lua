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

  local nuxt_ctx = {
    cmd = 'nuxt typecheck',
    title = 'nuxt typecheck',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({
      'ERROR  src/app.vue(15,7): TS2339: Property "foo" does not exist on type "{}".',
      '  at pages/index.vue',
    }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed_nuxt = ctx.state.parsers.ts_text(nuxt_ctx)
  t.expect(type(parsed_nuxt) == 'table', 'ts_text should parse prefixed Nuxt diagnostics')
  t.expect_eq(#parsed_nuxt.items, 1, 'ts_text should parse one prefixed Nuxt diagnostic')
  t.expect(parsed_nuxt.items[1].text:find('TS2339') ~= nil, 'ts_text should preserve TS code diagnostics')

  local nuxt_multiline_ctx = {
    cmd = 'nuxt typecheck',
    title = 'nuxt typecheck',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({
      ' ERROR  TS2339: Property "title" does not exist on type "{}".',
      ' FILE  pages/index.vue:22:15',
    }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed_nuxt_multiline = ctx.state.parsers.ts_text(nuxt_multiline_ctx)
  t.expect(type(parsed_nuxt_multiline) == 'table', 'ts_text should parse Nuxt multiline diagnostics')
  t.expect_eq(#parsed_nuxt_multiline.items, 1, 'ts_text should parse one Nuxt multiline diagnostic')
  t.expect(parsed_nuxt_multiline.items[1].text:find('TS2339') ~= nil, 'ts_text should keep Nuxt multiline TS code')
end
