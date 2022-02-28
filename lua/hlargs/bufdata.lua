local M = {}
local util = require 'hlargs.util'
local paint = require 'hlargs.paint'

local data = {}

M.TaskTypes = {
  PARTIAL = 1,
  TOTAL = 2,
  SLOW = 3
}

function M.get(bufnr)
  data[bufnr] = data[bufnr] or {
    change_idx = 0,
    tasks = {},
    debouncers = {},
    ranges_to_parse = {},
    main_ns = vim.api.nvim_create_namespace(''),
    marks_ns = vim.api.nvim_create_namespace(''),
    initialized = false
  }
  return data[bufnr]
end

function M.get_all()
  return data
end

function M.new_task(bufnr, type, mark)
  local buf_data = M.get(bufnr)
  buf_data.change_idx = buf_data.change_idx + 1

  local task = {
    mark = mark,
    change_idx = buf_data.change_idx,
    ns = vim.api.nvim_create_namespace(''),
    stop = false,
    type = type
  }

  table.insert(buf_data.tasks, task)
  return task
end

function M.total_parse_is_running(bufnr)
  local buf_data = M.get(bufnr)
  for _, t in ipairs(buf_data.tasks) do
    if t.type == M.TaskTypes.TOTAL then
      return true
    end
  end
  return false
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

-- Gets called on disable / BufDelete
function M.delete_data(bufnr)
  if data[bufnr] == nil then return end
  for _, t in ipairs(data[bufnr].tasks) do
    t.stop = true
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_del_extmark(bufnr, data[bufnr].marks_ns, t.mark)
      paint.clear(bufnr, t.ns)
    end
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    paint.clear(bufnr, data[bufnr].main_ns)
  end
  data[bufnr] = nil
end

function M.debug()
  util.i(data)
end

return M
