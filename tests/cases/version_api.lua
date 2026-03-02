return function(t)
  local quickmate = require 'quickmate'
  local version_mod = require 'quickmate.version'
  local version_file = io.open('VERSION', 'r')

  t.expect(version_file ~= nil, 'VERSION file should exist')
  local version_text = version_file and version_file:read('*a') or ''
  if version_file then
    version_file:close()
  end
  version_text = (version_text or ''):gsub('%s+$', '')

  t.expect(type(quickmate.VERSION) == 'string', 'quickmate.VERSION should be a string')
  t.expect(type(quickmate.version) == 'function', 'quickmate.version should be a function')
  t.expect_eq(quickmate.version(), quickmate.VERSION, 'quickmate.version() should return quickmate.VERSION')
  t.expect_eq(quickmate.VERSION, version_mod.current, 'quickmate.VERSION should match quickmate.version module')
  t.expect_eq(quickmate.VERSION, version_text, 'quickmate.VERSION should match VERSION file')
  t.expect(quickmate.VERSION:match('^%d+%.%d+%.%d+$') ~= nil, 'quickmate.VERSION should use semver core format')
end
