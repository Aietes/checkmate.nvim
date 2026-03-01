return function(t)
  local checkmate = require 'checkmate'
  local version_mod = require 'checkmate.version'
  local version_file = io.open('VERSION', 'r')

  t.expect(version_file ~= nil, 'VERSION file should exist')
  local version_text = version_file and version_file:read('*a') or ''
  if version_file then
    version_file:close()
  end
  version_text = (version_text or ''):gsub('%s+$', '')

  t.expect(type(checkmate.VERSION) == 'string', 'checkmate.VERSION should be a string')
  t.expect(type(checkmate.version) == 'function', 'checkmate.version should be a function')
  t.expect_eq(checkmate.version(), checkmate.VERSION, 'checkmate.version() should return checkmate.VERSION')
  t.expect_eq(checkmate.VERSION, version_mod.current, 'checkmate.VERSION should match checkmate.version module')
  t.expect_eq(checkmate.VERSION, version_text, 'checkmate.VERSION should match VERSION file')
  t.expect(checkmate.VERSION:match('^%d+%.%d+%.%d+$') ~= nil, 'checkmate.VERSION should use semver core format')
end
