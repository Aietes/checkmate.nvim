local util = require 'checkmate.util'

local M = {}

local patterns = {
  '^([~%./%w_%-%s]+)%((%d+),(%d+)%)%:%s*(.*)',
  '^([A-Za-z]:\\[^%(]+)%((%d+),(%d+)%)%:%s*(.*)',
  '^(.+):(%d+):(%d+)%s%-%s*(.*)',
}

---@param ctx checkmate.ParserContext
---@return checkmate.ParserResult|nil
function M.parse(ctx)
  local items = {}
  local current = nil

  for line in util.strip_ansi(ctx.combined):gmatch('([^\n]*)\n?') do
    local file, lnum, col, msg
    for _, pattern in ipairs(patterns) do
      file, lnum, col, msg = line:match(pattern)
      if file then
        break
      end
    end

    if file and msg then
      local lower = msg:lower()
      local diagnostic_like = lower:match '^error' or lower:match '^warning' or lower:match ' ts%d+'
      if not diagnostic_like then
        file, lnum, col, msg = nil, nil, nil, nil
      end
    end

    if file and msg then
      current = {
        filename = file,
        lnum = tonumber(lnum) or 1,
        col = tonumber(col) or 1,
        text = msg,
        type = msg:lower():match '^warning' and 'W' or 'E',
      }
      current = util.tag_item_source('tsc', current)
      items[#items + 1] = current
    elseif current and line:match '^%s+%S' then
      current.text = current.text .. ' ' .. line:gsub('^%s+', '')
    else
      current = nil
    end
  end

  if #items == 0 then
    return nil
  end
  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

return M
