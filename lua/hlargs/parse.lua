local M = {}

local ts = vim.treesitter
local ts_utils = require 'nvim-treesitter.ts_utils'
local queries = require 'vim.treesitter.query'
local config = require 'hlargs.config'
local util = require 'hlargs.util'

function M.get_args(func_node, bufnr)
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  local query = queries.get_query(filetype, 'function_arguments')

  local start_row, _, end_row, _ = func_node:range()
  local arg_names_set, arg_nodes = {}, {}
  for id, node in query:iter_captures(func_node, bufnr, start_row, end_row+1) do
    if util.get_first_function_parent(filetype, node) == func_node then
      table.insert(arg_nodes, node)
      local arg_name = ts_utils.get_node_text(node, bufnr)[1]
      arg_names_set[arg_name] = true
    end
  end

  return arg_nodes, arg_names_set
end

function M.get_body_node(func_node, bufnr)
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  local query = queries.get_query(filetype, 'function_body')

  local start_row, _, end_row, _ = func_node:range()
  for id, node in query:iter_captures(func_node, bufnr, start_row, end_row + 1) do
    return node
  end
end

function M.get_arg_usages(body_node, arg_names_set, bufnr)
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  local query = queries.get_query(filetype, 'variables')

  local start_row, _, end_row, _ = body_node:range()

  local usages_nodes = {}
  for id, node in query:iter_captures(body_node, bufnr, start_row, end_row+1) do
    if not util.ignore_node(filetype, node) then
      local arg_name = ts_utils.get_node_text(node, bufnr)[1]
      if arg_names_set[arg_name] then
        table.insert(usages_nodes, node)
      end
    end
  end
  return usages_nodes
end

function M.get_nodes_to_paint(bufnr)
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  local query = queries.get_query(filetype, 'function_definition')
  if query == nil then
    return
  end

  local parser = ts.get_parser(bufnr, filetype)
  local syntax_tree = parser:parse()
  local root = syntax_tree[1]:root()

  local start_row, _, end_row, _ = root:range()
  local i = 0
  for id, node in query:iter_captures(root, bufnr, start_row, end_row) do
    i = i+1
    if config.opts.performance.max_iterations > 0 and i > config.opts.performance.max_iterations then
      return
    end
    local name = query.captures[id] -- name of the capture
    local arg_nodes, arg_names_set = M.get_args(node, bufnr)
    local usages_nodes = {}
    if config.opts.paint_arg_usages then
      local body_node = M.get_body_node(node, bufnr)
      usages_nodes = M.get_arg_usages(body_node, arg_names_set, bufnr)
    end
    coroutine.yield(arg_nodes, usages_nodes)
  end
end

return M

