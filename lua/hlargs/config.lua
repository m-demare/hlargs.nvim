local M = {}

local defaults = {
  color = '#ef9062',
  highlight = {},
  excluded_filetypes = {},
  disable = function(lang, bufnr)
    return vim.tbl_contains(M.opts.excluded_filetypes, lang)
  end,
  paint_arg_declarations = true,
  paint_arg_usages = true,
  hl_priority = 10000,
  excluded_argnames = {
    declarations = {},
    usages = {
      python = { 'self', 'cls' },
      lua = { 'self' }
    }
  },
  performance = {
    parse_delay = 1,
    slow_parse_delay = 50,
    max_iterations = 400,
    max_concurrent_partial_parses = 50,
    debounce = {
      partial_parse = 3,
      partial_insert_mode = 100,
      total_parse = 700,
      slow_parse = 5000
    }
  }
}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  if vim.tbl_isempty(M.opts.highlight) then
    vim.api.nvim_set_hl(0, 'Hlargs', { fg = M.opts.color, default = true })
  else
    M.opts.highlight.default = true
    vim.api.nvim_set_hl(0, 'Hlargs', M.opts.highlight)
  end
end

return M

