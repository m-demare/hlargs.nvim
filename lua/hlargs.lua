local events = require "hlargs.events"
local config = require "hlargs.config"

local M = {}

M.setup = function(opts)
  if vim.fn.has "nvim-0.7" == 0 then
    vim.api.nvim_err_writeln [[
            Neovim 0.7 is required for this version of hlargs
            If you're using 0.6, check the README on the branch 0.6-compat
        ]]
  end
  config.setup(opts)
  if config.opts.enabled then M.enable() end
end
M.toggle = events.toggle
M.disable = events.disable
M.enable = events.enable

M.disable_buf = events.disable_buf
M.enable_buf = events.enable_buf

return M
