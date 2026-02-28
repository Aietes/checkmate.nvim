return function(t, ctx)
  local cwd = t.abs(ctx.root .. '/tmp-mixed')
  local combined = table.concat({
    "src/types.ts(1,1): error TS1005: ';' expected.",
    [[{"diagnostics":[{"filename":"src/ox.ts","line":4,"column":2,"message":"ox issue","severity":"error","code":"ox-rule"}]}]],
    [[ [{"filePath":"src/eslint.ts","messages":[{"ruleId":"semi","severity":2,"message":"Missing semicolon.","line":8,"column":14}]}] ]],
  }, '\n')
  local parser_ctx = {
    cmd = 'pnpm run check',
    title = 'pnpm run check',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = combined,
    errorformat = vim.o.errorformat,
  }

  local parsed = ctx.state.parsers.mixed_lint_json(parser_ctx)
  t.expect(type(parsed) == 'table', 'mixed_lint_json should parse mixed output')
  t.expect_eq(#parsed.items, 3, 'mixed_lint_json should merge ts, oxlint, and eslint items')

  local seen = {}
  for _, item in ipairs(parsed.items) do
    if item.user_data and item.user_data.source then
      seen[item.user_data.source] = true
    end
  end
  t.expect(seen.tsc == true, 'mixed_lint_json should include tsc items')
  t.expect(seen.oxlint == true, 'mixed_lint_json should include oxlint items')
  t.expect(seen.eslint == true, 'mixed_lint_json should include eslint items')
end
