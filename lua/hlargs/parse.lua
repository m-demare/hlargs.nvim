local M = {}

local ts = vim.treesitter
local ts_utils = require 'nvim-treesitter.ts_utils'
local queries = require 'vim.treesitter.query'
local config = require 'hlargs.config'
local util = require 'hlargs.util'

-- If arguments were modified, the whole function has to be reparsed
local function fix_mark(bufnr, marks_ns, root_node, mark)
  local filetype = util.get_filetype(bufnr)
  local query = queries.get_query(filetype, 'function_arguments')
  local orig_from, orig_to = util.get_marks_limits(bufnr, marks_ns, mark)
  local new_from, new_to = orig_from, orig_to
  for id, node in query:iter_captures(root_node, bufnr, orig_from, orig_to+1) do
    local start_row, _, end_row, _ = util.get_first_function_parent(filetype, node):range()
    if start_row < new_from then new_from = start_row end
    if end_row > new_to then new_to = end_row end
  end
  vim.api.nvim_buf_set_extmark(bufnr, marks_ns, new_from, 0, {
    id = mark,
    end_row = new_to,
    end_col = 0
  })
end

function M.get_args(bufnr, func_node)
  local filetype = util.get_filetype(bufnr)
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

function M.get_body_nodes(bufnr, func_node)
  local filetype = util.get_filetype(bufnr)
  local query = queries.get_query(filetype, 'function_body')

  local start_row, _, end_row, _ = func_node:range()
  local nodes = {}
  local i=0
  for id, node in query:iter_captures(func_node, bufnr, start_row, end_row + 1) do
    if i==0 or util.get_first_function_parent(filetype, node) == func_node then
      table.insert(nodes, node)
      if not util.is_multi_body_lang(filetype) then
        return nodes
      end
    end
    i = i+1
  end
  return nodes
end

function M.get_arg_usages(bufnr, body_nodes, arg_names_set, limits)
  local filetype = util.get_filetype(bufnr)
  local query = queries.get_query(filetype, 'variables')

  local usages_nodes = {}
  for _, body_node in ipairs(body_nodes) do
    local start_row, _, end_row, _ = body_node:range()
    if limits then start_row, end_row = limits[1], limits[2]-1 end

    for id, node in query:iter_captures(body_node, bufnr, start_row, end_row+1) do
      local arg_name = ts_utils.get_node_text(node, bufnr)[1]
      if arg_names_set[arg_name] and not util.ignore_node(filetype, node) then
        table.insert(usages_nodes, node)
      end
    end
  end
  return usages_nodes
end

function M.get_nodes_to_paint(bufnr, marks_ns, mark)
  local filetype = util.get_filetype(bufnr)
  local query = queries.get_query(filetype, 'function_definition')
  if query == nil then
    return
  end

  local parser = ts.get_parser(bufnr, filetype)
  local syntax_tree = parser:parse()
  local root = syntax_tree[1]:root()

  local start_row, _, end_row, _ = root:range()
  if mark then
    fix_mark(bufnr, marks_ns, root, mark)
    start_row, end_row = util.get_marks_limits(bufnr, marks_ns, mark)
  end

  local i = 0
  for id, node in query:iter_captures(root, bufnr, start_row, end_row) do
    i = i+1
    if config.opts.performance.max_iterations > 0 and i > config.opts.performance.max_iterations then
      return
    end
    local name = query.captures[id] -- name of the capture
    local arg_nodes, arg_names_set = M.get_args(bufnr, node)
    local usages_nodes = {}
    if config.opts.paint_arg_usages and #arg_nodes>0 then
      local body_nodes = M.get_body_nodes(bufnr, node)
      local limits = nil
      if mark then
        local from, to = util.get_marks_limits(bufnr, marks_ns, mark)
        limits = { from, to }
      end
      if body_nodes and #body_nodes>0 then
        -- So that empty functions don't fail
        usages_nodes = M.get_arg_usages(bufnr, body_nodes, arg_names_set, limits)
      end
    end
    coroutine.yield(arg_nodes, usages_nodes)
  end
end

return M

