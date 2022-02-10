local M = {}
local parser = require 'hlargs.parse'
local config = require 'hlargs.config'
local util = require 'hlargs.util'

local buf_data = {}
local enabled = false

local function clear(bufnr, ns)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

local function clear_all(bufnr, nss)
  for k,ns in ipairs(nss) do
    if ns then
      clear(bufnr, ns)
    end
  end
end

local function paint(bufnr, ns, node)
  local start_row, start_col, end_row, end_col = node:range()
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, start_row, start_col, {
    end_line = end_row,
    end_col = end_col,
    hl_group = "Hlargs",
    priority = 10000,
  })
end

local function paint_nodes(bufnr, ns, node_group)
  if not node_group then return end
  for i, node in ipairs(node_group) do
    paint(bufnr, ns, node)
  end
end

function find_and_paint_iteration(bufnr, ns, co, stopper)
  vim.defer_fn(function()
    if coroutine.status(co) ~= "dead" and not stopper.stop then
      local running, arg_nodes, usage_nodes = coroutine.resume(co, bufnr)
      if running then
        if config.opts.paint_arg_declarations then
          paint_nodes(bufnr, ns, arg_nodes)
        end
        paint_nodes(bufnr, ns, usage_nodes)
        find_and_paint_iteration(bufnr, ns, co, stopper)
      end
    else
      if not vim.api.nvim_buf_is_valid(bufnr) then
        buf_data[bufnr] = nil
      else
        clear_all(bufnr, buf_data[bufnr].namespaces.to_clean)
        buf_data[bufnr].namespaces.to_clean = { ns }
      end
    end
  end, config.opts.performance.parse_delay)
end

function M.find_and_paint_nodes(bufnr)
  if not enabled then return end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  if util.contains(config.opts.excluded_filetypes, filetype) then
    return
  end

  if not buf_data[bufnr] then
    buf_data[bufnr] = {
      namespaces = {
        to_clean = {}
      },
      coroutines = {
        stoppers = {}
      }
    }
  end

  for k,stopper in ipairs(buf_data[bufnr].coroutines.stoppers) do
    stopper.stop = true
  end
  local stopper = {}
  table.insert(buf_data[bufnr].coroutines.stoppers, stopper)

  co = coroutine.create(parser.get_nodes_to_paint)
  local ns = vim.api.nvim_create_namespace("")
  find_and_paint_iteration(bufnr, ns, co, stopper)

end

function M.enable()
  if not enabled then
    enabled = true
    vim.cmd([[
      augroup Hlargs
        autocmd!
        autocmd BufEnter,TextChanged,InsertLeavePre * lua require('hlargs.paint').find_and_paint_nodes()
      augroup end]])
    M.find_and_paint_nodes()
  end
end

function M.disable()
  if enabled then
    enabled = false
    pcall(vim.cmd, "autocmd! Hlargs")
    pcall(vim.cmd, "augroup! Hlargs")
    for bufnr, data in ipairs(buf_data) do
      for _, stopper in pairs(data.coroutines.stoppers) do
        stopper.stop = true
      end
      if vim.api.nvim_buf_is_valid(bufnr) then
        clear_all(bufnr, data.namespaces.to_clean)
        data.namespaces.to_clean = {}
      end
      buf_data[bufnr] = nil
    end
  end
end

return M

