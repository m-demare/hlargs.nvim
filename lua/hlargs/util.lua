local M = {}

local new_lang_api = vim.treesitter.language.register ~= nil

local ignored_field_names = {
  c_sharp = {
    member_access_expression = { "name" },
  },
  python = {
    _ = { "attribute", "name" },
  },
  lua = {
    dot_index_expression = { "field" },
    field = { "name" },
  },
  nix = {
    attrpath = { "attr" },
  },
  java = {
    method_invocation = { "name" },
    field_access = { "field" },
  },
  vim = {
    scoped_identifier = { "_" },
  },
}

local function julia_is_function_node(node)
  local node_type = node:type()
  if vim.tbl_contains({ "function_definition", "function_expression", "do_clause" }, node_type) then
    return true
  end
  if node_type == "assignment_expression" then
    if node:child(0):type() == "call_expression" then return true end
  end
  return false
end

-- stylua: ignore
local function_or_catch_node_validators = {
  astro = { },
  bash = { "function_definition" },
  c = { "function_definition" },
  cpp = { "function_definition", "lambda_expression", "catch_clause" },
  cuda = { "function_definition", "lambda_expression", "catch_clause" },
  c_sharp = { "constructor_declaration", "method_declaration", "lambda_expression" },
  go = { "function_declaration", "method_declaration", "func_literal" },
  java = { "method_declaration", "lambda_expression", "catch_clause" },
  javascript = { "function_declaration", "function_expression", "method_definition", "arrow_function", "catch_clause" },
  jsx = { "function_declaration", "function_expression", "method_definition", "arrow_function", "catch_clause" },
  julia = julia_is_function_node,
  kotlin = { "function_declaration", "lambda_literal", "secondary_constructor", "class_declaration", "catch_block" },
  lua = { "function_declaration", "function_definition" },
  nix = { "function_expression" },
  php = { "function_definition", "method_declaration", "anonymous_function", "arrow_function", "catch_clause" },
  python = { "function_definition", "lambda", "except_clause" },
  r = { "function_definition" },
  ruby = { "method", "lambda", "block", "do_block", "rescue" },
  rust = { "function_item" },
  solidity = { "function_declaration", "function_definition", "constructor_definition", "modifier_definition" },
  tsx = { "function_declaration", "function_expression", "method_definition", "arrow_function", "catch_clause" },
  typescript = { "function_declaration", "function_expression", "method_definition", "arrow_function", "catch_clause" },
  vim = { "function_definition", "lambda_expression" },
  zig = { "function_declaration" },
}

local multi_body_langs = { "ruby", "cpp", "cuda", "julia", "solidity" }
local no_arg_defs_langs = { "bash" }

function M.ignore_node(filetype, node)
  if ignored_field_names[filetype] and node:parent() then
    for ch, field_name in node:parent():iter_children() do
      if ch == node then
        local ignored_list
        if ignored_field_names[filetype][node:parent():type()] then
          ignored_list = ignored_field_names[filetype][node:parent():type()]
        else
          ignored_list = ignored_field_names[filetype]["_"] or {}
        end
        return vim.tbl_contains(ignored_list, field_name) or vim.tbl_contains(ignored_list, "_")
      end
    end
  end
  return false
end

local function is_function_or_catch_node(filetype, node)
  local validator = function_or_catch_node_validators[filetype]
  if type(validator) == "table" then
    return vim.tbl_contains(validator, node:type())
  elseif type(validator) == "function" then
    return validator(node)
  end
  return false
end

function M.get_first_function_parent(filetype, node)
  while node and not is_function_or_catch_node(filetype, node) do
    node = node:parent()
  end
  return node
end

-- Some languages (ejem, Ruby) don't have a single body node,
-- but instead everything after the parameters is body
function M.is_multi_body_lang(lang)
  return vim.tbl_contains(multi_body_langs, lang)
end

function M.has_no_arg_defs(lang)
  return vim.tbl_contains(no_arg_defs_langs, lang)
end

function M.get_marks_limits(bufnr, marks_ns, extmark)
  local mark_data = vim.api.nvim_buf_get_extmark_by_id(bufnr, marks_ns, extmark, { details = true })
  return mark_data[1], mark_data[3].end_row
end

-- Merges overlapping (or non overlapping, but
-- separated by up to a line) ranges in a list
function M.merge_ranges(bufnr, marks_ns, ranges)
  ranges = vim.tbl_filter(function(r)
    return r ~= nil
  end, ranges)
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
      if next_end > last_end then
        vim.api.nvim_buf_set_extmark(bufnr, marks_ns, last_start, 0, {
          id = last_added,
          end_row = next_end,
          end_col = 0,
          strict = false,
        })
      end
      vim.api.nvim_buf_del_extmark(bufnr, marks_ns, next)
    end
  end

  return merged_ranges
end

function M.get_lang(bufnr)
  local filetype = vim.fn.getbufvar(bufnr, "&filetype")
  if new_lang_api then
    return vim.treesitter.language.get_lang(filetype)
  else
    return require("nvim-treesitter.parsers").ft_to_lang(filetype)
  end
end

function M.is_supported(lang)
  return function_or_catch_node_validators[lang] ~= nil
end

function M.print_node_text(node, bufnr)
  local text = vim.treesitter.query.get_node_text(node, bufnr)
  for line = 1, #text do
    print(text[line])
  end
end

function M.tbl_spit_by(pred, tbl)
  return vim.tbl_filter(pred, tbl),
    vim.tbl_filter(function(entry)
      return not pred(entry)
    end, tbl)
end

return M
