local M = {}

local ts_utils = require 'nvim-treesitter.ts_utils'
local parsers = require 'nvim-treesitter.parsers'

local ignored_field_names = {
  python = {
    _ = { 'attribute', 'name' }
  },
  lua = {
    dot_index_expression = { 'field' },
    field = { 'name' }
  },
  java = {
    _ = { 'field' }
  },
  vim = {
    scoped_identifier = { '_' }
  }
}

local function_types = {
  c = { 'function_definition' },
  cpp = { 'function_definition', 'lambda_expression' },
  go = { 'function_declaration', 'method_declaration', 'func_literal' },
  java = { 'method_declaration', 'lambda_expression' },
  javascript = { 'function_declaration', 'method_definition', 'function', 'arrow_function' },
  jsx = { 'function_declaration', 'method_definition', 'function', 'arrow_function' },
  lua = { 'function_declaration', 'function_definition' },
  php = { 'function_definition', 'method_declaration', 'anonymous_function_creation_expression', 'arrow_function' },
  python = { 'function_definition', 'lambda' },
  rust = { 'function_item' },
  tsx = { 'function_declaration', 'method_definition', 'function', 'arrow_function' },
  typescript = { 'function_declaration', 'method_definition', 'function', 'arrow_function' },
  vim = { 'function_definition', 'lambda_expression' },
  zig = { 'TopLevelDecl'}
}

function M.ignore_node(filetype, node)
  if ignored_field_names[filetype] and node:parent() then
    for ch, field_name in node:parent():iter_children() do
      if ch == node then
        local ignored_list
        if ignored_field_names[filetype][node:parent():type()] then
          ignored_list = ignored_field_names[filetype][node:parent():type()]
        else
          ignored_list = ignored_field_names[filetype]['_'] or {}
        end
        return vim.tbl_contains(ignored_list, field_name) or vim.tbl_contains(ignored_list, '_')
      end
    end
  end
  return false
end

function M.get_first_function_parent(filetype, node)
  while node and not vim.tbl_contains(function_types[filetype], node:type()) do
    node = node:parent()
  end
  return node
end

function M.get_marks_limits(bufnr, marks_ns, extmark)
  local mark_data = vim.api.nvim_buf_get_extmark_by_id(bufnr, marks_ns, extmark, {details=true})
  return mark_data[1], mark_data[3].end_row
end

-- Merges overlapping (or non overlapping, but
-- separated by up to a line) ranges in a list
function M.merge_ranges(bufnr, marks_ns, ranges)
  if #ranges == 0 then return ranges end

  -- Sort by ranges' start position
  table.sort(ranges, function(a, b)
    a = M.get_marks_limits(bufnr, marks_ns, a)
    b = M.get_marks_limits(bufnr, marks_ns, b)
    return a < b
  end)

  local last_added = ranges[1]
  local merged_ranges = { last_added }
  for i = 2, #ranges do
    local next = ranges[i]
    local last_start, last_end = M.get_marks_limits(bufnr, marks_ns, last_added)
    local next_start, next_end = M.get_marks_limits(bufnr, marks_ns, next)

    if last_end + 2 < next_start then
      table.insert(merged_ranges, next)
      last_added = next
    else
      local delete_next = true
      if next_end > last_end then
        -- For some reason, this call might fail with `end_row value outside range`,
        -- even though end_row literally comes from another extmark (and acording to
        -- logs, it is within range)
        -- Strict=false might fix this (https://github.com/neovim/neovim/pull/17001)
        -- I couldn't reproduce this consistently
        local ok, _ = pcall(vim.api.nvim_buf_set_extmark, bufnr, marks_ns, last_start, 0, {
          id = last_added,
          -- end_row = math.min(next_end, vim.api.nvim_buf_line_count(bufnr)),
          end_row = next_end,
          end_col = 0
        })
        delete_next = ok
        if not delete_next then
          table.insert(merged_ranges, next)
          last_added = next
        end
      end
      if delete_next then
        vim.api.nvim_buf_del_extmark(bufnr, marks_ns, next)
      end
    end
  end

  return merged_ranges
end

function M.get_filetype(bufnr)
    local filetype = vim.fn.getbufvar(bufnr, '&filetype')
    return parsers.ft_to_lang(filetype)
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

