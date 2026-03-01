return function(t, ctx)
  local expected = {
    'efm',
    'oxlint_json',
    'eslint_json',
    'cargo_json',
    'luacheck',
    'luacheck_text',
    'ts_text',
    'mixed_lint_json',
    'oxlint',
    'eslint_text',
    'eslint',
  }

  for _, name in ipairs(expected) do
    t.expect(type(ctx.state.parsers[name]) == 'function', 'missing parser: ' .. name)
  end
end
