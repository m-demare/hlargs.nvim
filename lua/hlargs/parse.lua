local M = {}

local ts = vim.treesitter
local config = require "hlargs.config"
local util = require "hlargs.util"

local ts_get_query
local ts_get_node_text
if vim.fn.has "nvim-0.9" == 1 then
  ts_get_query, ts_get_node_text = ts.query.get, ts.get_node_text
else
  ts_get_query, ts_get_node_text = ts.query.get_query, ts.query.get_node_text
end

---@param node TSNode
---@param lang string
---@param new_from integer
---@param new_to integer
---@return integer new_from
---@return integer new_to
local function fix_range(node, lang, new_from, new_to)
  local start_row, _, end_row, _ = util.get_first_function_parent(lang, node):range()
  if start_row < new_from then new_from = start_row end
  if end_row > new_to then new_to = end_row end
  return new_from, new_to
end

-- If arguments were modified, or if extras.unused_args is enabled,
-- the whole function has to be reparsed
---@param lang string
---@param bufnr integer
---@param marks_ns integer
---@param root_node TSNode
---@param mark integer
local function fix_mark(lang, bufnr, marks_ns, root_node, mark)
  local orig_from, orig_to = util.get_marks_limits(bufnr, marks_ns, mark)
  local new_from, new_to = orig_from, orig_to
  local arg_query = ts_get_query(lang, "function_arguments")

  for _, node in arg_query:iter_captures(root_node, bufnr, orig_from, orig_to + 1) do
    new_from, new_to = fix_range(node, lang, new_from, new_to)
    break
  end
  if config.opts.extras.unused_args then
    local var_query = ts_get_query(lang, "variables")
    for _, node in var_query:iter_captures(root_node, bufnr, orig_from, orig_to + 1) do
      new_from, new_to = fix_range(node, lang, new_from, new_to)
      break
    end
  end

  vim.api.nvim_buf_set_extmark(bufnr, marks_ns, new_from, 0, {
    id = mark,
    end_row = new_to,
    end_col = 0,
  })
end

---@param bufnr integer
---@param lang string
---@param func_node TSNode
---@return TSNode[] arg_nodes
---@return table<string, string> arg_names_set
function M.get_args(bufnr, lang, func_node)
  if util.has_no_arg_defs(lang) then return {}, {} end

  local query = ts_get_query(lang, "function_arguments")
  local start_row, _, end_row, _ = func_node:range()
  local arg_names_set, arg_nodes = {}, {}
  for id, node in query:iter_captures(func_node, bufnr, start_row, end_row + 1) do
    local capture_name = query.captures[id]
    if util.get_first_function_parent(lang, node) == func_node then
      if capture_name ~= "catch" or config.opts.paint_catch_blocks.declarations then
        table.insert(arg_nodes, node)
      end
      local arg_name = ts_get_node_text(node, bufnr)
      arg_names_set[arg_name] = capture_name
    end
  end

  return arg_nodes, arg_names_set
end

---@param bufnr integer
---@param lang string
---@param func_node TSNode
---@return TSNode[] nodes
function M.get_body_nodes(bufnr, lang, func_node)
  local query = ts_get_query(lang, "function_body")

  local start_row, _, end_row, _ = func_node:range()
  local nodes = {}
  local i = 0
  for _, node in query:iter_captures(func_node, bufnr, start_row, end_row + 1) do
    if i == 0 or util.get_first_function_parent(lang, node) == func_node then
      table.insert(nodes, node)
      if not util.is_multi_body_lang(lang) then return nodes end
    end
    i = i + 1
  end
  return nodes
end

---@param bufnr integer
---@param lang string
---@param body_nodes TSNode[]
---@param arg_names_set table<string, string>
---@param limits? { [1]: integer, [2]: integer }
---@return TSNode[] usage_nodes
---@return table<string, boolean> used_args
function M.get_arg_usages(bufnr, lang, body_nodes, arg_names_set, limits)
  local query = ts_get_query(lang, "variables")
  local has_no_arg_defs = util.has_no_arg_defs(lang)

  local used_args, usages_nodes = {}, {} ---@type table<string, boolean>, TSNode[]
  for _, body_node in ipairs(body_nodes) do
    local start_row, _, end_row, _ = body_node:range()
    if limits then
      start_row, end_row = limits[1], limits[2]
    end

    for id, node in query:iter_captures(body_node, bufnr, start_row, end_row + 1) do
      local capture_name = query.captures[id]
      if capture_name ~= "ignore" then
        local arg_name = ts_get_node_text(node, bufnr)
        if (arg_names_set[arg_name] or has_no_arg_defs) and not util.ignore_node(lang, node) then
          if config.opts.extras.unused_args then used_args[arg_name] = true end
          if arg_names_set[arg_name] ~= "catch" or config.opts.paint_catch_blocks.usages then
            table.insert(usages_nodes, node)
          end
        end
      end
    end
  end
  return usages_nodes, used_args
end

---@param bufnr integer
---@param excluded_names string[]
---@return fun(node: TSNode): boolean
local function not_excluded_name(bufnr, excluded_names)
  return function(node)
    return not vim.list_contains(excluded_names, ts_get_node_text(node, bufnr))
  end
end

---@param bufnr integer
---@param marks_ns integer
---@param mark integer
function M.get_nodes_to_paint(bufnr, marks_ns, mark)
  local lang = util.get_lang(bufnr)

  local parser = ts.get_parser(bufnr, lang)
  if not parser then return end

  local syntax_tree = parser:parse()
  if not syntax_tree then return end

  for _, tree in ipairs(syntax_tree) do
    M.get_nodes_to_paint_in_tree(bufnr, lang, tree, marks_ns, mark)
  end

  for ch_lang, ch_parser in pairs(parser:children()) do
    syntax_tree = ch_parser:parse()
    for _, tree in ipairs(syntax_tree or {}) do
      M.get_nodes_to_paint_in_tree(bufnr, ch_lang, tree, marks_ns, mark)
    end
  end
end

---@param bufnr integer
---@param lang string
---@param tree TSTree
---@param marks_ns integer
---@param mark integer
function M.get_nodes_to_paint_in_tree(bufnr, lang, tree, marks_ns, mark)
  local root = tree:root()
  local has_no_arg_defs = util.has_no_arg_defs(lang)

  local query = ts_get_query(lang, "function_definition")
  if query == nil then return end

  local start_row, _, end_row, _ = root:range()
  if mark then
    fix_mark(lang, bufnr, marks_ns, root, mark)
    start_row, end_row = util.get_marks_limits(bufnr, marks_ns, mark)
  end

  local i = 0
  for _, node in query:iter_captures(root, bufnr, start_row, end_row) do
    i = i + 1
    if
      config.opts.performance.max_iterations > 0 and i > config.opts.performance.max_iterations
    then
      return
    end
    -- local name = query.captures[id] -- name of the capture
    local arg_nodes, arg_names_set = M.get_args(bufnr, lang, node)
    local usages_nodes, used_args = {}, {}
    if config.opts.paint_arg_usages and (#arg_nodes > 0 or has_no_arg_defs) then
      local body_nodes = M.get_body_nodes(bufnr, lang, node)
      local limits = nil ---@type nil|{ [1]: integer, [2]: integer }
      if mark then
        local from, to = util.get_marks_limits(bufnr, marks_ns, mark)
        limits = { from, to }
      end
      if body_nodes and #body_nodes > 0 then
        -- So that empty functions don't fail
        usages_nodes, used_args = M.get_arg_usages(bufnr, lang, body_nodes, arg_names_set, limits)
      end
    end
    if config.opts.excluded_argnames.declarations[lang] then
      arg_nodes = vim.tbl_filter(
        not_excluded_name(bufnr, config.opts.excluded_argnames.declarations[lang]),
        arg_nodes
      )
    end
    if config.opts.excluded_argnames.usages[lang] then
      usages_nodes = vim.tbl_filter(
        not_excluded_name(bufnr, config.opts.excluded_argnames.usages[lang]),
        usages_nodes
      )
    end
    local used_arg_nodes, unused_arg_nodes = arg_nodes, {}
    if config.opts.extras.unused_args then
      used_arg_nodes, unused_arg_nodes = util.tbl_spit_by(function(argnode)
        return used_args[ts_get_node_text(argnode, bufnr)] or false
      end, arg_nodes)
    end
    coroutine.yield(used_arg_nodes, unused_arg_nodes, usages_nodes)
  end
end

return M
