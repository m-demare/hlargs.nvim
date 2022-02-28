local events = require("hlargs.events")
local config = require("hlargs.config")

local M = {}

M.setup = function(opts)
    config.setup(opts)
    M.enable()
end
M.toggle = events.toggle
M.disable = events.disable
M.enable = events.enable

return M
