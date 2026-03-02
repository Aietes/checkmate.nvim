local util = require 'quickmate.util'

local M = {}

---@param line string
---@return table|nil
local function decode_json_line(line)
  local ok, decoded = pcall(vim.json.decode, line)
  if ok and type(decoded) == 'table' then
    return decoded
  end
  return nil
end

---@param sev string|nil
---@return string
local function map_severity(sev)
  local level = type(sev) == 'string' and sev:lower() or ''
  return level == 'error' and 'E' or 'W'
end

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse_json2(ctx)
  local lines = vim.split(util.strip_ansi(ctx.combined), '\n', { plain = true })
  local items = {}
  local saw_selene_output = false

  for _, line in ipairs(lines) do
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed ~= '' then
      local event = decode_json_line(trimmed)
      if event then
        local event_type = event.type
        if event_type == 'Diagnostic' then
          saw_selene_output = true
          local label = type(event.primary_label) == 'table' and event.primary_label or {}
          local span = type(label.span) == 'table' and label.span or {}
          local filename = type(label.filename) == 'string' and label.filename or ''
          local lnum = (tonumber(span.start_line) or 0) + 1
          local col = (tonumber(span.start_column) or 0) + 1
          local code = type(event.code) == 'string' and event.code or 'selene'
          local message = type(event.message) == 'string' and event.message or ''
          items[#items + 1] = util.tag_item_source('selene', {
            filename = filename,
            lnum = lnum,
            col = col,
            text = string.format('[%s] %s', code, message),
            type = map_severity(event.severity),
          })
        elseif event_type == 'Summary' then
          saw_selene_output = true
        end
      end
    end
  end

  if #items == 0 then
    if saw_selene_output then
      return { items = {}, ok = true }
    end
    return nil
  end
  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse_text(ctx)
  local lines = vim.split(util.strip_ansi(ctx.combined), '\n', { plain = true })
  local items = {}
  local saw_selene_output = false

  for _, line in ipairs(lines) do
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed ~= '' then
      local file, lnum, col, severity, code, message =
        trimmed:match('^(.+):(%d+):(%d+):%s*(%a+)%[([%w_]+)%]:%s*(.+)$')
      if file and lnum and col and severity and code and message then
        saw_selene_output = true
        items[#items + 1] = util.tag_item_source('selene', {
          filename = file,
          lnum = tonumber(lnum) or 1,
          col = tonumber(col) or 1,
          text = string.format('[%s] %s', code, message),
          type = map_severity(severity),
        })
      elseif trimmed:match '^Results:' or trimmed:match '^%d+%s+errors?' or trimmed:match '^%d+%s+warnings?' then
        saw_selene_output = true
      end
    end
  end

  if #items == 0 then
    if saw_selene_output then
      return { items = {}, ok = true }
    end
    return nil
  end
  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse(ctx)
  return M.parse_json2(ctx) or M.parse_text(ctx)
end

return M
