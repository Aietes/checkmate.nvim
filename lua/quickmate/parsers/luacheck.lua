local util = require 'quickmate.util'

local M = {}

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse_text(ctx)
  local lines = vim.split(util.strip_ansi(ctx.combined), '\n', { plain = true })
  local items = {}
  local saw_luacheck_output = false

  for _, line in ipairs(lines) do
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed ~= '' then
      if trimmed:match '^Checking%s+' or trimmed:match '^Total:%s+' then
        saw_luacheck_output = true
      end
    end
    if trimmed ~= '' and not trimmed:match '^Checking%s+' and not trimmed:match '^Total:%s+' then
      local file, lnum, col, code, msg = trimmed:match('^(.+):(%d+):(%d+):%s*%(([EW]%d+)%)%s*(.+)$')
      if file and lnum and col and code and msg then
        saw_luacheck_output = true
        items[#items + 1] = util.tag_item_source('luacheck', {
          filename = file,
          lnum = tonumber(lnum) or 1,
          col = tonumber(col) or 1,
          text = string.format('(%s) %s', code, msg),
          type = code:sub(1, 1) == 'E' and 'E' or 'W',
        })
      else
        local file2, lnum2, code2, msg2 = trimmed:match('^(.+):(%d+):%s*%(([EW]%d+)%)%s*(.+)$')
        if file2 and lnum2 and code2 and msg2 then
          saw_luacheck_output = true
          items[#items + 1] = util.tag_item_source('luacheck', {
            filename = file2,
            lnum = tonumber(lnum2) or 1,
            col = 1,
            text = string.format('(%s) %s', code2, msg2),
            type = code2:sub(1, 1) == 'E' and 'E' or 'W',
          })
        else
          local file3, lnum3, col3, msg3 = trimmed:match('^(.+):(%d+):(%d+):%s*(.+)$')
          if file3 and lnum3 and col3 and msg3 then
            saw_luacheck_output = true
            local severity = msg3:lower():match '%f[%a]error%f[%A]' and 'E' or 'W'
            items[#items + 1] = util.tag_item_source('luacheck', {
              filename = file3,
              lnum = tonumber(lnum3) or 1,
              col = tonumber(col3) or 1,
              text = msg3,
              type = severity,
            })
          else
            local file4, lnum4, msg4 = trimmed:match('^(.+):(%d+):%s*(.+)$')
            if file4 and lnum4 and msg4 then
              saw_luacheck_output = true
              local severity = msg4:lower():match '%f[%a]error%f[%A]' and 'E' or 'W'
              items[#items + 1] = util.tag_item_source('luacheck', {
                filename = file4,
                lnum = tonumber(lnum4) or 1,
                col = 1,
                text = msg4,
                type = severity,
              })
            end
          end
        end
      end
    end
  end

  if #items == 0 then
    if saw_luacheck_output then
      return { items = {}, ok = true }
    end
    return nil
  end
  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse(ctx)
  return M.parse_text(ctx)
end

return M
