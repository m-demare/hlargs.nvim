local M = {}

local ts = vim.treesitter
local ts_utils = require 'nvim-treesitter.ts_utils'
local queries = require 'vim.treesitter.query'

local function print_node(node)
    print(string.format("Node: type '%s', name '%s'", node:type(), node:named()))
end

local function i(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

local function print_node_text(node)
  local text = ts_utils.get_node_text(node, bufnr)
  for line = 1, #text do
    print(text[line])
  end
end

function M.get_args(func_node, bufnr)
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  local query = queries.get_query(filetype, 'function_arguments')

  local start_row, _, end_row, _ = func_node:range()
  local arg_names_set, arg_nodes = {}, {}
  for id, node in query:iter_captures(func_node, bufnr, start_row, end_row+1) do
    local parent = node:parent()
    if parent == func_node or parent:parent() == func_node then
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
  -- print_node_text(body_node)

  local start_row, _, end_row, _ = body_node:range()

  local usages_nodes = {}
  for id, node in query:iter_captures(body_node, bufnr, start_row, end_row+1) do
    local arg_name = ts_utils.get_node_text(node, bufnr)[1]
    if arg_names_set[arg_name] then
      table.insert(usages_nodes, node)
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
  local all_arg_nodes, all_usage_nodes = {}, {}
  for id, node in query:iter_captures(root, bufnr, start_row, end_row) do
    local name = query.captures[id] -- name of the capture
    local arg_nodes, arg_names_set = M.get_args(node, bufnr)
    local body_node = M.get_body_node(node, bufnr)
    local usages_nodes = M.get_arg_usages(body_node, arg_names_set, bufnr)
    table.insert(all_arg_nodes, arg_nodes)
    table.insert(all_usage_nodes, usages_nodes)
  end
  return all_arg_nodes, all_usage_nodes
end

return M

