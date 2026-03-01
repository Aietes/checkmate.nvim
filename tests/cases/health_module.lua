return function(t)
  local health = require 'checkmate.health'
  t.expect(type(health) == 'table', 'health module should load')
  t.expect(type(health.check) == 'function', 'health module should expose check()')
end
