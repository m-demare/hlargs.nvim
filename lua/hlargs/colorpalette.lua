local config = require "hlargs.config"
local parse = require "hlargs.parse"
local util = require "hlargs.util"

---@class HlArgs.ColorPalette
local M = {}

-- https://cp-algorithms.com/string/string-hashing.html
local P = 103
local MAX_INT = 1e9 + 9

---@param arg_name string
---@return integer hash_value
local function hash_arg(arg_name)
  local hash_value = 0
  local p_pow = 1
  for i = 1, arg_name:len() do
    local ascii = arg_name:byte(i)
    hash_value = (hash_value + ascii * p_pow) % MAX_INT
    p_pow = (p_pow * P) % MAX_INT
  end
  return hash_value
end

---@param arg_name string
---@return string hashed_hlgroup
function M.get_hlgroup_hashed(arg_name)
  local opts = config.opts
  local size = #opts.colorpalette
  local idx = hash_arg(arg_name)
  local current_color = idx % size

  return "Hlarg" .. tonumber(current_color)
end

---@param bufnr integer
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@param arg_name string
---@return string sequential_hlgroup
function M.get_hlgroup_sequential(bufnr, start_row, start_col, end_row, end_col, arg_name)
  local lang = util.get_lang(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, lang)
  if not parser then return "" end

  local node =
    parser:parse()[1]:root():named_descendant_for_range(start_row, start_col, end_row, end_col)
  local functionNode = util.get_first_function_parent(lang, node)
  local arg_nodes, _ = parse.get_args(bufnr, "", functionNode)
  local current_color = 1
  local node_index = 1
  for _, arg_node in ipairs(arg_nodes) do
    local node_name = vim.treesitter.get_node_text(arg_node, bufnr)
    if node_name == arg_name then
      current_color = node_index
      break
    end
    node_index = node_index + 1
  end
  return "Hlarg" .. tonumber(current_color)
end

return M
