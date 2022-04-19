local M = {}

local ts = vim.treesitter
local ts_utils = vim.treesitter.query
local ts_locals = require 'nvim-treesitter.locals'
local queries = vim.treesitter.query
local config = require 'hlargs.config'
local util = require 'hlargs.util'

-- If arguments were modified, the whole function has to be reparsed
local function fix_mark(bufnr, marks_ns, root_node, mark)
  local lang = util.get_lang(bufnr)
  local query = queries.get_query(lang, 'function_arguments')
  local orig_from, orig_to = util.get_marks_limits(bufnr, marks_ns, mark)
  local new_from, new_to = orig_from, orig_to
  for id, node in query:iter_captures(root_node, bufnr, orig_from, orig_to+1) do
    local start_row, _, end_row, _ = util.get_first_function_parent(lang, node):range()
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
  local lang = util.get_lang(bufnr)
  local query = queries.get_query(lang, 'function_arguments')

  local start_row, _, end_row, _ = func_node:range()
  local arg_names_set, arg_nodes = {}, {}
  for id, node in query:iter_captures(func_node, bufnr, start_row, end_row+1) do
    if util.get_first_function_parent(lang, node) == func_node then
      table.insert(arg_nodes, node)
      local arg_name = ts_utils.get_node_text(node, bufnr)[1]
      arg_names_set[arg_name] = node
    end
  end

  return arg_nodes, arg_names_set
end

function M.get_body_nodes(bufnr, func_node)
  local lang = util.get_lang(bufnr)
  local query = queries.get_query(lang, 'function_body')

  local start_row, _, end_row, _ = func_node:range()
  local nodes = {}
  local i=0
  for id, node in query:iter_captures(func_node, bufnr, start_row, end_row + 1) do
    if i==0 or util.get_first_function_parent(lang, node) == func_node then
      table.insert(nodes, node)
      if not util.is_multi_body_lang(lang) then
        return nodes
      end
    end
    i = i+1
  end
  return nodes
end

function M.get_arg_usages(bufnr, body_nodes, arg_names_set, limits)
  local lang = util.get_lang(bufnr)
  local query = queries.get_query(lang, 'variables')

  local usages_nodes = {}
  for _, body_node in ipairs(body_nodes) do
    local start_row, _, end_row, _ = body_node:range()
    if limits then start_row, end_row = limits[1], limits[2] end

    for id, node in query:iter_captures(body_node, bufnr, start_row, end_row+1) do
      local arg_name = ts_utils.get_node_text(node, bufnr)[1]
      if arg_names_set[arg_name] and not util.ignore_node(lang, node) then
        local def_node, _, kind = ts_locals.find_definition(node, bufnr)
        if kind == nil or def_node == arg_names_set[arg_name] then
          table.insert(usages_nodes, node)
        end
      end
    end
  end
  return usages_nodes
end

local function not_excluded_name(bufnr, excluded_names)
  return function (node)
    return not vim.tbl_contains(excluded_names, ts_utils.get_node_text(node, bufnr)[1])
  end
end

function M.get_nodes_to_paint(bufnr, marks_ns, mark)
  local lang = util.get_lang(bufnr)
  local query = queries.get_query(lang, 'function_definition')
  if query == nil then
    return
  end

  local parser = ts.get_parser(bufnr, lang)
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
    if config.opts.excluded_argnames.declarations[lang] then
      arg_nodes = vim.tbl_filter(not_excluded_name(bufnr, config.opts.excluded_argnames.declarations[lang]), arg_nodes)
    end
    if config.opts.excluded_argnames.usages[lang] then
      usages_nodes = vim.tbl_filter(not_excluded_name(bufnr, config.opts.excluded_argnames.usages[lang]), usages_nodes)
    end
    coroutine.yield(arg_nodes, usages_nodes)
  end
end

return M

