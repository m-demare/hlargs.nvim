local uv = vim.uv or vim.loop

---@class HlArgs.Async
local M = {}

---@param bufnr integer
---@param callbacks vim.api.keyset.buf_attach
---@return function
function M.attach(bufnr, callbacks)
  local detached = false

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(...)
      if detached then return true end
      callbacks.on_lines(...)
    end,
    on_reload = function(...)
      if detached then return end
      callbacks.on_reload(...)
    end,
  })

  return function()
    detached = true
  end
end

---@param fn function
---@param time integer
---@return function
function M.defer(fn, time)
  local cancelled = false
  local t = vim.defer_fn(function()
    if cancelled then return end
    fn()
  end, time)
  -- stylua: ignore
  return function ()
    cancelled = true  -- It seems like there's some sort of race condition with these
                      -- timers, they occasionally get executed after being cancelled.
                      -- This flag prevents that behaviour.
    uv.timer_stop(t)
  end
end

return M
