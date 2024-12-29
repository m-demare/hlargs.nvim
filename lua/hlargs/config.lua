local M = {}

local defaults = {
  enabled = true,
  color = "#ef9062",
  use_colorpalette = false,
  sequential_colorpalette = false,
  colorpalette = {
    { fg = "#ef9062" },
    { fg = "#3AC6BE" },
    { fg = "#35D27F" },
    { fg = "#EB75D6" },
    { fg = "#E5D180" },
    { fg = "#8997F5" },
    { fg = "#D49DA5" },
    { fg = "#7FEC35" },
    { fg = "#F6B223" },
    { fg = "#F67C1B" },
    { fg = "#DE9A4E" },
    { fg = "#BBEA87" },
    { fg = "#EEF06D" },
    { fg = "#8FB272" },
  },
  highlight = {},
  excluded_filetypes = {},
  disable = function(lang, bufnr)
    return vim.tbl_contains(M.opts.excluded_filetypes, lang)
  end,
  paint_arg_declarations = true,
  paint_arg_usages = true,
  paint_catch_blocks = {
    declarations = false,
    usages = false,
  },
  extras = {
    named_parameters = false,
    unused_args = false,
  },
  hl_priority = 120,
  excluded_argnames = {
    declarations = {},
    usages = {
      python = { "self", "cls" },
      lua = { "self" },
    },
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
      slow_parse = 5000,
    },
  },
}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})

  local function create_hl_groups()
    if M.opts.use_colorpalette then
      for i, color in pairs(M.opts.colorpalette) do
        color.default = true
        if not vim.tbl_isempty(M.opts.highlight) then
          color = vim.tbl_deep_extend("force", color, M.opts.highlight)
        end
        vim.api.nvim_set_hl(0, "Hlarg" .. i, color)
      end
    else
      if vim.tbl_isempty(M.opts.highlight) then
        vim.api.nvim_set_hl(0, "Hlargs", { fg = M.opts.color, default = true })
      else
        M.opts.highlight.default = true
        vim.api.nvim_set_hl(0, "Hlargs", M.opts.highlight)
      end
    end
    if M.opts.extras.unused_args then
      vim.api.nvim_set_hl(0, "HlargsUnused", M.opts.extras.unused_args)
    end

    if M.opts.extras.named_parameters then
      if M.opts.extras.named_parameters == true then M.opts.extras.named_parameters = { link = "Hlargs" } end
      vim.api.nvim_set_hl(0, "@HlargsNamedParams", M.opts.extras.named_parameters)
    end
  end

  create_hl_groups()

  local augroup = vim.api.nvim_create_augroup("hlargs-create-hlgroups", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = create_hl_groups,
    group = augroup,
  })
end

return M
