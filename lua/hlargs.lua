local paint = require("hlargs.paint")
local config = require("hlargs.config")

local M = {}

M.setup = function(opts)
    config.setup(opts)
    M.enable()
end
M.toggle = paint.toggle
M.disable = paint.disable
M.enable = paint.enable

return M
