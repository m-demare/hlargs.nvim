local M = {}
local ns = vim.api.nvim_create_namespace("hlargs")
local parser = require("hlargs.parse")
local config = require("hlargs.config")

local enabled = false

local function clear(bufnr, from, to)
  from = from or 0
  to = to or -1
  if from < 0 then
    from = 0
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, from, to)
end

local function paint(bufnr, node)
  local start_row, start_col, end_row, end_col = node:range()
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, start_row, start_col, {
    end_line = end_row,
    end_col = end_col,
    hl_group = "Hlargs",
    priority = 10000,
  })
end

local function paint_nodes(bufnr, node_groups)
  if not node_groups then return end
  for i, node_group in ipairs(node_groups) do
    for j, node in ipairs(node_group) do
      paint(bufnr, node)
    end
  end
end

local function contains(arr, val)
    for i, value in ipairs(arr) do
        if value == val then
            return true
        end
    end
    return false
end

function M.find_and_paint_nodes(bufnr)
  if not enabled then return end
  clear(bufnr)

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  if contains(config.opts.excluded_filetypes, filetype) then
    return
  end

  local all_arg_nodes, all_usage_nodes = parser.get_nodes_to_paint(bufnr)
  if config.opts.paint_arg_declarations then
    paint_nodes(bufnr, all_arg_nodes)
  end
  if config.opts.paint_arg_usages then
    paint_nodes(bufnr, all_usage_nodes)
  end
end

function M.enable()
  if not enabled then
    enabled = true
    vim.cmd([[
      augroup Hlargs
        autocmd!
        autocmd BufEnter,TextChanged * lua require('hlargs.paint').find_and_paint_nodes()
      augroup end]])
    M.find_and_paint_nodes()
  end
end

function M.disable()
  if enabled then
    enabled = false
    pcall(vim.cmd, "autocmd! Hlargs")
    pcall(vim.cmd, "augroup! Hlargs")
    for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        clear(bufnr)
      end
    end
  end
end

vim.cmd("highlight! def Hlargs guifg=" .. config.opts.color)

return M

