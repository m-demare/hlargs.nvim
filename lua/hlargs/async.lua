local function attach(bufnr, callabcks)
  local detached = false

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(...)
      if detached then return true end
      callabcks.on_lines(...)
    end,
    on_reload = function(...)
      if detached then return true end
      callabcks.on_reload(...)
    end,
  })

  return function()
    detached = true
  end
end

local function defer(fn, time)
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
    vim.loop.timer_stop(t)
  end
end

return {
  attach = attach,
  defer = defer,
}
