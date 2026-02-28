local M = {}

local default_spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

---@param opts table|nil
---@return table
function M.start(opts)
  opts = opts or {}
  local id_prefix = opts.id_prefix or 'progress_'
  local id = opts.id or (id_prefix .. tostring(vim.uv.hrtime()))
  local title = opts.title or 'Progress'
  local message = opts.message or 'in progress'
  local interval = opts.interval or 80
  local level = opts.level or vim.log.levels.INFO
  local spinner = opts.spinner or default_spinner
  local timer = vim.uv.new_timer()

  if timer then
    timer:start(0, interval, vim.schedule_wrap(function()
      local idx = math.floor(vim.uv.hrtime() / (1e6 * interval)) % #spinner + 1
      vim.notify(string.format('%s %s', spinner[idx], message), level, {
        id = id,
        title = title,
        history = false,
      })
    end))
  end

  return {
    id = id,
    title = title,
    timer = timer,
  }
end

---@param handle table|nil
function M.stop(handle)
  if not handle or not handle.timer then
    return
  end
  handle.timer:stop()
  handle.timer:close()
  handle.timer = nil
end

---@param handle table|nil
---@param message string
---@param level integer|nil
---@param opts table|nil
function M.finish(handle, message, level, opts)
  opts = opts or {}
  M.stop(handle)
  vim.notify(message, level or vim.log.levels.INFO, {
    id = handle and handle.id or opts.id,
    title = opts.title or (handle and handle.title) or 'Progress',
    history = opts.history ~= false,
  })
end

return M
