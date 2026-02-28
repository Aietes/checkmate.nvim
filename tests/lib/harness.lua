local M = {}

M.assertions = 0

---@param cond boolean
---@param message string
function M.expect(cond, message)
  M.assertions = M.assertions + 1
  if not cond then
    error(message, 2)
  end
end

---@param actual any
---@param expected any
---@param message string
function M.expect_eq(actual, expected, message)
  M.expect(vim.deep_equal(actual, expected), string.format('%s\nexpected: %s\nactual: %s', message, vim.inspect(expected), vim.inspect(actual)))
end

---@param path string
---@return string
function M.abs(path)
  return vim.fn.fnamemodify(path, ':p')
end

return M
