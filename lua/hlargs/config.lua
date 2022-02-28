local M = {}

local defaults = {
  color = "#ef9062",
  excluded_filetypes = {},
  paint_arg_declarations = true,
  paint_arg_usages = true,
  hl_group = 'Hlargs',
  hl_priority = 10000,
  performance = {
    parse_delay = 1,
    slow_parse_delay = 50,
    max_iterations = 400,
    debounce = {
      partial_parse = 3,
      partial_insert_mode = 500,
      total_parse = 700,
      slow_parse = 5000
    }
  }
}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  vim.cmd("highlight clear " .. M.opts.hl_group)
  vim.cmd("highlight! def " .. M.opts.hl_group .. " guifg=" .. M.opts.color)
end

M.setup()

return M

