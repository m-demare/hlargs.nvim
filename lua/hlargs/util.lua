local M = {}

local ts_utils = require 'nvim-treesitter.ts_utils'

local ignored_field_names = {
  python = { 'attribute' },
  lua = { 'field' },
  java = { 'field' }
}

local function_types = {
  javascript = { 'function_declaration', 'method_definition', 'function', 'arrow_function' },
  typescript = { 'function_declaration', 'method_definition', 'function', 'arrow_function' },
  python = { 'function_definition', 'lambda' },
  lua = { 'function_declaration', 'function_definition' },
  cpp = { 'function_definition', 'lambda_expression' },
  java = { 'method_declaration', 'lambda_expression' }
}

function M.contains(arr, val)
  for i, value in ipairs(arr) do
      if value == val then
          return true
      end
  end
  return false
end

function M.ignore_node(filetype, node)
  if ignored_field_names[filetype] and node:parent() then
    for ch, field_name in node:parent():iter_children() do
      if ch == node and M.contains(ignored_field_names[filetype], field_name) then
        return true
      end
    end
  end
  return false
end

function M.get_first_function_parent(filetype, node)
    while node and not M.contains(function_types[filetype], node:type()) do
        node = node:parent()
    end
    return node
end

function M.i(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

function M.print_node_text(node, bufnr)
  local text = ts_utils.get_node_text(node, bufnr)
  for line = 1, #text do
    print(text[line])
  end
end

return M

