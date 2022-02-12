local M = {}

local defaults = {
  color = "#ef9062",
  excluded_filetypes = {},
  paint_arg_declarations = true,
  paint_arg_usages = true,
  performance = {
    parse_delay = 1,
    max_iterations = 400
  }
}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  vim.cmd("highlight clear Hlargs")
  vim.cmd("highlight! def Hlargs guifg=" .. M.opts.color)
end

M.setup()

return M

