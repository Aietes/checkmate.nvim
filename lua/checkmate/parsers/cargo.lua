local util = require 'checkmate.util'

local M = {}

---@param ctx checkmate.ParserContext
---@return checkmate.ParserResult|nil
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
            if type(filename) == 'string' and filename ~= '' then
              local code_suffix = ''
              if type(message.code) == 'table' and message.code.code then
                code_suffix = ' [' .. tostring(message.code.code) .. ']'
              end
              items[#items + 1] = {
                filename = filename,
                lnum = tonumber(primary.line_start) or 1,
                col = tonumber(primary.column_start) or 1,
                end_lnum = tonumber(primary.line_end) or nil,
                end_col = tonumber(primary.column_end) or nil,
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
