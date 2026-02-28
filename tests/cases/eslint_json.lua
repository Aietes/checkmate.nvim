return function(t, ctx)
  local cwd = t.abs(ctx.root .. '/tmp-eslint')
  local parser_ctx = {
    cmd = 'eslint -f json .',
    title = 'eslint',
    cwd = cwd,
    stdout = [[
      {
        "filePath": "src/app.ts",
        "messages": [
          {
            "ruleId": "no-console",
            "severity": 2,
            "message": "Unexpected console statement.",
            "line": 12,
            "column": 5
          }
        ]
      }
    ]],
    stderr = '',
    combined = '',
    errorformat = vim.o.errorformat,
  }
  parser_ctx.stdout = '[' .. parser_ctx.stdout .. ']'

  local parsed = ctx.state.parsers.eslint_json(parser_ctx)
  t.expect(type(parsed) == 'table', 'eslint_json should parse json payload')
  t.expect_eq(#parsed.items, 1, 'eslint_json should produce one item')

  local item = parsed.items[1]
  t.expect_eq(item.filename, t.abs(vim.fs.joinpath(cwd, 'src/app.ts')), 'eslint_json should normalize filename to absolute path')
  t.expect_eq(item.type, 'E', 'eslint_json should map severity to E')
  t.expect(item.text:find('%[eslint%]') ~= nil, 'eslint_json should tag item source')
end
