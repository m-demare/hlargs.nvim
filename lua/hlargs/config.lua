local M = {}

local defaults = {
  color = "#ef9062",
  excluded_filetypes = {},
  paint_arg_declarations = true,
  paint_arg_usages = true,
  hl_priority = 10000,
  performance = {
    parse_delay = 1,
    slow_parse_delay = 50,
    max_iterations = 400,
    max_concurrent_partial_parses = 30,
    debounce = {
      partial_parse = 3,
      partial_insert_mode = 100,
      total_parse = 700,
      slow_parse = 5000
    }
  }
}

local hl_group = "Hlargs"

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  vim.cmd("highlight clear " .. hl_group)
  vim.cmd("highlight! def " .. hl_group .. " guifg=" .. M.opts.color)
end

M.setup()

return M

