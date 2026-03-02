local util = require 'quickmate.util'

local M = {}

---@class quickmate.CargoSpan
---@field file_name? string
---@field line_start? integer
---@field column_start? integer
---@field line_end? integer
---@field column_end? integer
---@field is_primary? boolean

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse_json(ctx)
  local lines = vim.split(ctx.combined, '\n', { plain = true })
  local items = {}

  for _, line in ipairs(lines) do
    local trimmed = util.strip_newlines(line)
    if trimmed ~= '' and (trimmed:sub(1, 1) == '{' or trimmed:sub(1, 1) == '[') then
      local ok, decoded = pcall(vim.json.decode, trimmed)
      if ok and type(decoded) == 'table' then
        if decoded.reason == 'compiler-message' and type(decoded.message) == 'table' then
          local message = decoded.message
          local level = message.level
          if level == 'error' or level == 'warning' then
            local primary = nil
            if type(message.spans) == 'table' then
              for _, span in ipairs(message.spans) do
                if span.is_primary then
                  primary = span
                  break
                end
              end
              if not primary then
                primary = message.spans[1]
              end
            end
            local filename = primary and primary.file_name or nil
            if type(filename) == 'string' and filename ~= '' and type(primary) == 'table' then
              ---@type quickmate.CargoSpan
              local primary_span = primary
              local line_start = tonumber(primary_span.line_start)
              local col_start = tonumber(primary_span.column_start)
              local line_end = tonumber(primary_span.line_end)
              local col_end = tonumber(primary_span.column_end)
              local code_suffix = ''
              if type(message.code) == 'table' and message.code.code then
                code_suffix = ' [' .. tostring(message.code.code) .. ']'
              end
              items[#items + 1] = {
                filename = filename,
                lnum = line_start or 1,
                col = col_start or 1,
                end_lnum = line_end,
                end_col = col_end,
                text = (message.message or 'cargo diagnostic') .. code_suffix,
                type = util.qf_type_from_severity(level),
              }
              items[#items] = util.tag_item_source('cargo', items[#items])
            end
          end
        end
      end
    end
  end

  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

return M
