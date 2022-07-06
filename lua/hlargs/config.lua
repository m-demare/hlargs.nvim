local M = {}

local defaults = {
  color = '#ef9062',
  use_colorpalette = false,
  colorpalette = {"#F5FA1D", "#F97C65", "#35D27F", "#EB75D6", "#E5D180", "#8997F5", "#D49DA5", "#7FEC35", "#F6B223", "#B4F1C3", "#99B730", "#F67C1B", "#3AC6BE", "#EAAFF1", "#DE9A4E", "#BBEA87", "#EEF06D", "#8FB272"},
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
  if M.opts.use_colorpalette then
    table.insert(M.opts.colorpalette, 1, M.opts.color)
    for i, color in pairs(M.opts.colorpalette) do
       vim.api.nvim_set_hl(0, 'Hlarg' .. i, {fg = color, default=true})
    end
  end
end

return M

