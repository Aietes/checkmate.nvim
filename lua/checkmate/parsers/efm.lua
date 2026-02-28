local M = {}

---@param lines string
---@param errorformat string
---@return checkmate.ParserResult
function M.parse(lines, errorformat)
  local qf = vim.fn.getqflist({
    lines = vim.split(lines, '\n', { plain = true }),
    efm = errorformat,
  })
  return { items = qf.items or {}, ok = true }
end

return M
