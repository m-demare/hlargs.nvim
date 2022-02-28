local M = {}
local util = require 'hlargs.util'
local paint = require 'hlargs.paint'

local data = {}

function M.get(bufnr)
  data[bufnr] = data[bufnr] or {
    dirty = false,
    change_idx = 0,
    tasks = {},
    debouncers = {},
    ranges_to_parse = {},
    main_ns = vim.api.nvim_create_namespace(''),
    marks_ns = vim.api.nvim_create_namespace('')
  }
  return data[bufnr]
end

function M.new_task(bufnr, mark)
  local buf_data = M.get(bufnr)
  buf_data.change_idx = buf_data.change_idx + 1
  buf_data.dirty = true

  local task = {
    mark = mark,
    change_idx = buf_data.change_idx,
    ns = vim.api.nvim_create_namespace(''),
    stop = false
  }

  if not mark then
    M.stop_total_parses(bufnr)
  end

  table.insert(buf_data.tasks, task)
  return task
end

function M.stop_total_parses(bufnr)
  local buf_data = M.get(bufnr)
  for _, t in ipairs(buf_data.tasks) do
    if not t.mark then
      t.stop = true
    end
  end
end

function M.end_task(bufnr, task)
  local buf_data = M.get(bufnr)
  local limits = nil
  if task.mark then
    local from, to = util.get_marks_limits(bufnr, buf_data.marks_ns, task.mark)
    limits = { from, to }
  end

  for _, t in ipairs(buf_data.tasks) do
    if t.change_idx < task.change_idx then
      paint.clear(bufnr, t.ns, limits)
      paint.combine_nss(bufnr, t.ns, task.ns, limits)
    end
  end

  -- Merge changes to main
  if limits then
    paint.clear(bufnr, buf_data.main_ns, limits)
    paint.combine_nss(bufnr, buf_data.main_ns, task.ns, limits)
    paint.clear(bufnr, task.ns)
  else
    paint.clear(bufnr, buf_data.main_ns)
    buf_data.main_ns = task.ns
  end

  if task.mark then
    vim.api.nvim_buf_del_extmark(bufnr, buf_data.marks_ns, task.mark)
  end
  for i = #buf_data.tasks, 1, -1 do
    if buf_data.tasks[i] == task then
      table.remove(buf_data.tasks, i)
    end
  end
end

function M.delete_data(bufnr)
  data[bufnr] = nil
  -- TODO limpiar namespaces y marks si todavía es válido el bufnr
end

function M.debug()
  util.i(data)
end

return M
